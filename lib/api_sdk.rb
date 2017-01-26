# TODO: extract the symbolize keys to a function

require 'active_record'
require 'net/http'
require 'json'
require 'faraday'

class Class
  # Custom accessor with support for dirty objects
  def changeable_attr_accessor(*args)
    args.each do |arg|
      # getter
      self.class_eval("def #{arg};@#{arg};end")
      # setter
      self.class_eval("def #{arg}=(val);#{arg}_will_change! unless val==@#{arg};@#{arg}=val;end")
    end
  end
end

module APISdk
  class Dataset
    # Introspections, conversions, translations and validations
    include ActiveModel::Model
    # Track dirty objects
    include ActiveModel::Dirty
    # Provides support for define_model_callbacks
    # to change persisted state on update, etc.
    extend ActiveModel::Callbacks

    # Class variables: supported connectors and providers
    @@connector_types     = %w(document json rest)
    @@connector_providers = %w(csv rwjson cartodb featureservice)

    # Accessors
    define_attribute_methods :name, :connector_type, :provider, :connector_url, :application
    changeable_attr_accessor :name, :connector_type, :provider, :connector_url, :application
    attr_accessor            :persisted, :id

    # Validations: TODO
    # The validation for application: can it be an empty array?
    validates :name,           presence: true
    validates :connector_type, presence: true
    validates :connector_type, :inclusion => { :in => @@connector_types }
    validates :application,    presence: true
    validate  :validate_application

    # Called on Dataset.new
    def initialize(data = {})
      super
      @errors = ActiveModel::Errors.new(self)
      self.attributes = data unless data == {}
      # A new object is not persisted by default
      @persisted = false
      clear_changes_information
    end

    # This enables the declaration of datasets with a hash of symbols,
    # like ControlTower::Dataset.new(name: "The name", ... )
    def attributes=(data)
    end

    # An object is persisted in the database if it's got an ID and is clean
    def persisted?
      @persisted ? @id && !self.changed? : nil
    end

    # Reset the dataset to its initial state
    def rollback!
      restore_attributes
    end
    
    # Get a dataset from the API
    def self.find(dataset_id)
      response = DatasetService.fetch(dataset_id)
      if response[:status] == 200 then
        # API always returns in camelCase, doesn't it?
        data = response[:dataset_parameters]
        dataset = Dataset.new(
                              id: data[:id].freeze,
                              name: data[:attributes]["name"],
                              connector_type: data[:attributes]["connectorType"],
                              provider: data[:attributes]["provider"],
                              connector_url: data[:attributes]["connectorUrl"],
                              application: data[:attributes]["application"]
                             )          
        dataset.persisted = true
        return dataset
      else
        puts(response[:status])
        return nil        
      end
    end

    def update
      changes = self.changes.symbolize_keys
      params = changes.map {|key, val| {key => val.last}}.reduce(:merge)
      result = DatasetService.update(self.id, params)
      if result[:status] == 200 then
        self.persisted = true
        clear_changes_information
        return result
      else
        puts(result[:status])
        return nil
      end
    end

    def delete
      result = DatasetService.destroy(self.id)
      if
        result[:status] == 200
      then
        return self.freeze
      else
        puts "Dataset not deleted: #{result}"
        return self
      end
    end

    def destroy
      # Not implemented - calls on_destroy callbacks
      nil
    end

    
    # Validations must be private
    private

    # ID shouln't be something the user changes
    define_attribute_methods :id
    
    def validate_application
      if !@application.is_a?(Array)
        @errors.add(:application, :not_an_array, message: "must be an array")
      elsif !@application.all? {|a| a.is_a? String}
        @errors.add(:application, :array, message: "must be an array of strings")
      end
    end

  end

  class DatasetService
    # For now targeting my dev server
    #@conn ||= Faraday.new(:url => ENV.fetch("API_URL")) do |faraday|
    @conn ||= Faraday.new(:url => "http://mymachine:9000") do |faraday|
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
      end

    def self.destroy(dataset_id)
      request = @conn.delete do |req|
        req.url "/dataset/#{dataset_id}"
        req.headers['Content-Type'] = 'application/json'
      end
      if request.status == 200
        result = JSON.parse request.body
        puts(result)
        # Poor man's symbolize_keys!
        return {status: request.status, dataset_parameters: result}
      else
        return {status: request.status, dataset_parameters: nil}
      end
    end

    def self.fetch(dataset_id)
      request = @conn.get do |req|
        req.url "/dataset/#{dataset_id}"
        req.headers['Content-Type'] = 'application/json'
      end
      if request.status == 200
        result = JSON.parse request.body
        data = result["data"]
        puts(data)
        # Poor man's symbolize_keys!
        data.keys.each do |key|
          data[(key.to_sym rescue key) || key] = data.delete(key)
        end
        return {status: request.status, dataset_parameters: data}
      else
        return {status: request.status, dataset_parameters: nil}
      end
    end

    def self.update(dataset_id, params)
      request = @conn.put do |req|
        req.url "/dataset/#{dataset_id}"
        req.headers['Content-Type'] = 'application/json'
        req.body = params.to_json
      end
        if request.status == 200
        result = JSON.parse request.body
        data = result["data"]
        puts("DATA: #{data}")
        # Poor man's symbolize_keys!
        data.keys.each do |key|
          data[(key.to_sym rescue key) || key] = data.delete(key)
        end
        puts("SYMBOLIZED DATA: #{data}")
        # API always returns in camelCase, doesn't it?
        return {status: request.status, dataset: data}
      else
        return {status: request.status, dataset: nil}
      end
    end    
  end
end
