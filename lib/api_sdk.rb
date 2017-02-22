# coding: utf-8
#
# TODO: validations
#
#
#
# I'm trying to offer some of the Rails interface
# for its models, so we'll need active_record
require 'active_record'
# And also select pieces of active_support
require 'active_support/core_ext'
# Also, the usual http and json stuff
require 'net/http'
require 'json'
# This gem will handle API calls
require 'httparty'
# And some code modularization is in order
# Some Rails magic is required.
require 'api_sdk/attr_changeable_methods'
# And the actual API interfacing will be living in its own class
require 'api_sdk/vocabulary'
# Needed for change-tracking in hash values
require 'api_sdk/dataset_service'
# Needed for change-tracking in hash values


module APISdk
  # Many years later, as he faced the firing squad, Colonel
  # Aureliano Buendía was to remember that distant afternoon when
  # his father took him to discover Rails.
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

    # FIELDS:
    #  name
    #  connector_type
    #  provider
    #  connector_url
    #  application
    #  subtitle
    #  data_path
    #  legend
    #  data
    #  table_name
    #  data_overwrite
    #  vocabularies
    #
    # Defining attribute methods in the usual Rails way, but
    # changeable_attr_accessor
    define_attribute_methods :name,
                             :connector_type,
                             :provider,
                             :connector_url,
                             :application,
                             :subtitle,
                             :data_path,
                             :legend,
                             :data,
                             :table_name,
                             :data_overwrite,
                             :vocabularies,
                             # We want to define accessors for all
                             # dataset attributes. But also, for
                             # some things that are not attributes.
                             # Like the token.
                             :token

    # But we'll only declare dataset attributes as changeable
    changeable_attr_accessor :name,
                             :connector_type,
                             :provider,
                             :connector_url,
                             :application,
                             :subtitle,
                             :data_path,
                             :legend,
                             :data,
                             :table_name,
                             :data_overwrite,
                             :vocabularies


    # Some of the stuff is not supposed to be changed by the user.
    attr_accessor            :persisted,
                             :token,
                             :id

    # Validations: TODO
    validates :name,           presence: true
    validates :connector_type, presence: true
    validates :connector_type, :inclusion => { :in => @@connector_types }
    validates :application,    presence: true
    validate  :validate_application
    validate  :validate_data

    # Called on Dataset.new
    def initialize(data = {})
      super
      @errors = ActiveModel::Errors.new(self)
      self.attributes = data unless data == {}
      # A new object is not persisted by default
      @persisted = false

      # And we reset the changes tracking
      clear_changes_information
    end

    # Strange, but necessary for Rails.
    # This enables the declaration of datasets with a hash of symbols,
    # like ControlTower::Dataset.new(name: "The name", ... )
    def attributes=(data)
    end

    #
    def attributes
      {
        name:            @name,
        connector_type:  @connector_type,
        provider:        @provider,
        connector_url:   @connector_url,
        application:     @application,
        subtitle:        @subtitle,
        data_path:       @data_path,
        legend:          @legend,
        data:            @data,
        table_name:      @table_name,
        data_overwrite:  @data_overwrite,
        vocabularies:    @vocabularies
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

    # Registers a dataset
    # Ugly function, has to be refactored
    def create
      response = DatasetService.create(self.attributes, self.token)
      puts "RESPONSE: #{response}"
      @id                 = response["data"]["id"]
      response = DatasetService.read(@id)
      puts "NEW RESPONSE: #{response}"
      self.name           = response["data"]["attributes"]["name"]
      # Important! The RW API accepts parameters in camelcase and snakecase,
      # but will return values in camelcase exclusively
      self.connector_type     = response["data"]["attributes"]["connectorType"]
      self.provider           = response["data"]["attributes"]["provider"]
      self.connector_url      = response["data"]["attributes"]["connectorUrl"]
      self.application        = response["data"]["attributes"]["application"]
      self.subtitle           = response["data"]["attributes"]["subtitle"]
      self.data_path          = response["data"]["attributes"]["dataPath"]
      self.legend             = response["data"]["attributes"]["legend"]
      self.data               = response["data"]["attributes"]["data"]
      self.table_name         = response["data"]["attributes"]["tableName"]
      self.data_overwrite     = response["data"]["attributes"]["dataOverwrite"]
      self.vocabularies       = response["data"]["attributes"]["vocabulary"]
      @persisted              = true
      clear_changes_information
      return self
    end

    # Get a dataset from the API
    def self.find(dataset_id)
      response = DatasetService.read(dataset_id)
      puts "Dataset response: #{response}"
      dataset = Dataset.new(
        name:           response["data"]["attributes"]["name"],
        connector_type: response["data"]["attributes"]["connectorType"],
        provider:       response["data"]["attributes"]["provider"],
        connector_url:  response["data"]["attributes"]["connectorUrl"],
        application:    response["data"]["attributes"]["application"],
        subtitle:       response["data"]["attributes"]["subtitle"],
        legend:         response["data"]["attributes"]["legend"],
        data:           response["data"]["attributes"]["data"],
        table_name:     response["data"]["attributes"]["tableName"],
        data_overwrite: response["data"]["attributes"]["dataOverwrite"]
      )

      dataset.id = response["data"]["id"]

      # Gets all vocabularies for this dataset
      vocab_response = VocabularyService.read_vocabularies(dataset.id)
      puts "VOCAB RESPONSE: #{vocab_response}"
      vocabularies_hash = vocab_response["data"]
      puts "VOCAB HASH: #{vocabularies_hash}"
      puts "Creating vocabularies for dataset #{dataset.id}"
      vocabularies_array = vocabularies_hash.map do |voc|
        puts "Vocabulary: #{voc}"
        puts "Vocabulary name: #{voc["attributes"]["name"]}"
        Vocabulary.new(
          name: voc["attributes"]["name"],
          tags: voc["attributes"]["tags"]
        )
      end
      dataset.vocabularies = vocabularies_array
      dataset.persisted = true
      return dataset
    end

    def update
      changed_parameters = self.changes.map{|k,v| {k =>  v.last}}.reduce(:merge)
      response = DatasetService.update(self.id, changed_parameters, self.token)
      puts("RESPONSE: #{response}")

      @id                 = response["data"]["id"]
      self.name           = response["data"]["attributes"]["name"]
      self.connector_type = response["data"]["attributes"]["connectorType"]
      self.provider       = response["data"]["attributes"]["provider"]
      self.connector_url  = response["data"]["attributes"]["connectorUrl"]
      self.application    = response["data"]["attributes"]["application"]
      self.subtitle       = response["data"]["attributes"]["subtitle"]
      self.data_path      = response["data"]["attributes"]["dataPath"]
      self.legend         = response["data"]["attributes"]["legend"]
      self.data           = response["data"]["attributes"]["data"]
      self.table_name     = response["data"]["attributes"]["tableName"]
      self.data_overwrite = response["data"]["attributes"]["dataOverwrite"]
      self.vocabularies   = response["data"]["attributes"]["vocabularies"]
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
        @errors.add(:application, :not_an_array, message: "Application must be an array")
      elsif @application == []
        @errors.add(:application, :is_empty_array, message: "Application can't be an empty array")
      elsif !@application.all? {|a| a.is_a? String}
        @errors.add(:application, :not_strings_array, message: "Application must be a string array")
      end
    end

    def validate_data
      case @provider
      when "json"
        (@data.nil? and @connector_url.nil?) ? @errors.add(
          :base,
          :neither_data_or_url,
          message: "Needed one of data or connector_url"
        ) : nil
        @data and @connector_url ? @errors.add(
              :base,
              :both_data_and_url,
              message: "You need only one of data or connector_url"
            ) : nil
      else
        @connector_url.nil? ? @errors.add(
          :connector_url,
          :presence,
          message: "Connector_url is needed"
        ) : nil
        @data.nil? ? nil : @errors.add(
          :data,
          :not_presence,
          message: "Data attribute not supported for this provider"
        )
      end
    end

    def validate_table_name
      case @provider
      when "gee"
       nil 
      end
    end
  end
end
