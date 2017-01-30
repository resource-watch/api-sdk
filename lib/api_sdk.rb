# TODO: extract the symbolize keys to a function
require 'active_record'
require 'net/http'
require 'json'
require 'httparty'
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
    # Serializations allow us to convert the object to serializable hashes:
    # a = APISdk::Dataset.new(...); a.serializable_hash
    include ActiveModel::Serialization
    # to_json and as_json methodsOB
    include ActiveModel::Serializers::JSON
    
    # Class variables: supported connectors and providers
    @@connector_types     = %w(document json rest)
    @@connector_providers = %w(csv rwjson cartodb featureservice)

    # Accessors
    define_attribute_methods :name, :connector_type, :provider, :connector_url, :application, :token 
    changeable_attr_accessor :name, :connector_type, :provider, :connector_url, :application
    attr_accessor            :persisted, :token, :id, :user_token
    
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

    # def changed_attributes
    #   if self.changed?
    #     return self.changes.map{|k,v| {k =>  v.last}}.reduce(:merge)
    #   else
    #     return {}
    #   end
    # end
    
    # Registers a dataset
    # :name, :connector_type, :provider, :connector_url, :application
    def create
      response = DatasetService.create({
                                         name: self.name,
                                         connector_type: self.connector_type,
                                         provider: self.provider,
                                         connector_url: self.connector_url,
                                         application: self.application
                                       },
                                       self.token
                                      )
      puts "RESPONSE: #{response}"
      @id = response["data"]["id"]
      self.name           = response["data"]["attributes"]["name"]
      self.connector_type = response["data"]["attributes"]["connectorType"]
      self.provider       = response["data"]["attributes"]["provider"]
      self.connector_url  = response["data"]["attributes"]["connectorUrl"]
      self.application    = response["data"]["attributes"]["application"]
      @persisted          = true
      clear_changes_information
      return self        
    end

    
    # Get a dataset from the API
    def self.find(dataset_id)
      response = DatasetService.read(dataset_id)
      puts "RESPONSE: #{response}"
      dataset = Dataset.new(
        name:           response["data"]["attributes"]["name"],
        connector_type: response["data"]["attributes"]["connectorType"],
        provider:       response["data"]["attributes"]["provider"],
        connector_url:  response["data"]["attributes"]["connectorUrl"],
        application:    response["data"]["attributes"]["application"]
      )

      dataset.id = response["data"]["id"]
      dataset.persisted = true
      return dataset
    end
    
    def update
      changed_parameters = self.changes.map{|k,v| {k =>  v.last}}.reduce(:merge)
      response = DatasetService.update(self.id, changed_parameters, self.token)
      puts("RESPONSE: #{response}")

      @id = response["data"]["id"]
      self.name           = response["data"]["attributes"]["name"]
      self.connector_type = response["data"]["attributes"]["connectorType"]
      self.provider       = response["data"]["attributes"]["provider"]
      self.connector_url  = response["data"]["attributes"]["connectorUrl"]
      self.application    = response["data"]["attributes"]["application"]
      @persisted          = true
      clear_changes_information
      return self        
    end
    
    def delete
      response = DatasetService.delete(self.id, self.token)
      return self.freeze
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
