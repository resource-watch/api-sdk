# TODO: extract the symbolize keys to a function
require 'active_record'
require 'net/http'
require 'json'
require 'faraday'
require 'api_sdk/dataset_service'

module APISdk
  class Dataset
    # Introspections, conversions, translations and validations
    include ActiveModel::Model
    # Track dirty objects
    include ActiveModel::Dirty
    # Provides support for define_model_callbacks
    # to change persisted state on update, etc.
    extend ActiveModel::Callbacks
    # to_key, to_param
    include ActiveModel::Conversion
    # AttributeMethods adds support for my_dataset.attributes
    include ActiveModel::AttributeMethods
    
    
    # Class variables: supported connectors and providers
    @@connector_types     = %w(document json rest)
    @@connector_providers = %w(csv rwjson cartodb featureservice)

    # Accessors
    define_attribute_methods :name, :connector_type, :provider, :connector_url, :application
    changeable_attr_accessor :name, :connector_type, :provider, :connector_url, :application
    attr_accessor            :persisted
    attr_reader              :id
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

    def attributes
      {
        name: @name,
        connector_type: @connector_type,
        provider: @provider,
        connector_url: @connector_url,
        application: @application        
      }
    end

    # An object is persisted in the database if it's got an ID and is clean
    def persisted?
      @persisted ? self.id && !self.changed? : nil
    end

    # Reset the dataset to its initial state
    def rollback!
      restore_attributes
    end

    # Create a dataset
    # :name, :connector_type, :provider, :connector_url, :application
    def create
      if
        self.id != nil 
      then
        puts "Object not created"
        return self
      else
        response = DatasetService.create({
                                           name: self.name,
                                           connector_type: self.connector_type,
                                           provider: self.provider,
                                           connector_url: self.connector_url,
                                           application: self.application
                                        })
        data = response[:dataset_parameters]

        puts "DATA: #{data}"

        @id                 = data[:id]
        self.name           = data[:attributes]["name"]
        self.connector_type = data[:attributes]["connectorType"]
        self.provider       = data[:attributes]["provider"]
        self.connector_url  = data[:attributes]["connectorUrl"]
        self.application    = data[:attributes]["application"]
        self.persisted      = true
        clear_changes_information
        return self
      end
    end

    # Get a dataset from the API
    def self.find(dataset_id)
      response = DatasetService.read(dataset_id)
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
      # This should update FROm the values in the db too
      changes = self.changes.symbolize_keys
      params = changes.map {|key, val| {key => val.last}}.reduce(:merge)
      response = DatasetService.update(self.id, params)
      if response[:status] == 200 then
        self.persisted = true
        clear_changes_information
        return response
      else
        puts(response[:status])
        return nil
      end
    end

    def delete
      response = DatasetService.delete(self.id)
      if
        response[:status] == 200
      then
        return self.freeze
      else
        puts "Dataset not deleted: #{response}"
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


end
