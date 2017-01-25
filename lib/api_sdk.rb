require 'active_record'
require 'net/http'
require 'json'
require 'faraday'

module APISdk
  class Dataset
    include ActiveModel::Model
    
    @@connector_types     = %w(document json rest)
    @@connector_providers = %w(csv rwjson cartodb featureservice)

    attr_accessor :id, :name, :connector_type, :provider, :connector_url, :application, :persisted

    # TODO
    validates :name,           presence: true
    validates :connector_type, presence: true
    validates :connector_type, :inclusion => { :in => @@connector_types }
    validates :application,    presence: true
    validate  :validate_application

    def initialize(data = {})
      super
      @errors = ActiveModel::Errors.new(self)
      self.attributes = data unless data == {}
      @persisted = false
    end

    # This allows to declare objects with a hash of symbols,
    # like
    # ControlTower::Dataset.new(name: "The name", ... )
    def attributes=(data)
    end

    def persisted?
      @persisted ? @persisted : nil
    end    

    private
    
    def validate_application
      if !@application.is_a?(Array)
        @errors.add(:application, :array, message: "must be an array")
      elsif !@application.all? {|a| a.is_a? String}
        @errors.add(:application, :array, message: "must be an array of strings")
      end
    end

    # For now targeting my dev server
    #@conn ||= Faraday.new(:url => ENV.fetch("API_URL")) do |faraday|
    @conn ||= Faraday.new(:url => "http://mymachine:9000") do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    
    def self.fetch(dataset_id)
      request = @conn.get "/dataset/#{dataset_id}"
      if request.body.blank?
        return {}
      else
        result = JSON.parse request.body
        data = result["data"]
        puts(data)
        # Poor man's symbolize_keys!
        data.keys.each do |key|
          data[(key.to_sym rescue key) || key] = data.delete(key)
        end
        puts(data)
        
        # API always returns in camelCase, doesn't it?
        dataset = Dataset.new(
          id: data[:id],
          name: data[:attributes]["name"],
          connector_type: data[:attributes]["connectorType"],
          provider: data[:attributes]["provider"],
          connector_url: data[:attributes]["connectorUrl"],
          application: data[:attributes]["application"]
        )

        
        dataset.persisted = true
        return dataset

        # TODO: after_update
      end
    end
  end
end
