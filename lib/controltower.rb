require 'active_record'
require 'net/http'
require 'json'

module ControlTower
  class Dataset
    include ActiveModel::Model
    
    @@connector_types     = %w(document json rest)
    @@connector_providers = %w(csv rwjson cartodb featureservice)
    @@token = ENV["CONTROL_TOWER_TOKEN"]
    #    @@host = ENV["CONTROL_TOWER_HOST"]
    @@host = URI("http://mymachine:9000")
    @@path = 'dataset'

    attr_accessor :name, :connector_type, :connector_provider, :connector_url, :application

    validates :name,           presence: true
    validates :connector_type, presence: true
    validates :connector_type, :inclusion => { :in => @@connector_types }
    validates :application,    presence: true
    validate  :validate_application

    def initialize
      @errors = ActiveModel::Errors.new(self)
    end

    def register
      if self.valid?
        conn = Net::HTTP.new(
          @@host.host,
          @@host.port
        )

        req = Net::HTTP::Post.new(
          @@path,
          'Content-Type' => 'application/json'
        )

        req.body = {
          name: @name,
          connector_type: @connector_type,
          connector_provider: @connector_provider,
          connector_url: @connector_url,
          application: @application
        }.to_json

        res = conn.request(req)
        return res
      else
        puts("The dataset is not valid")
        @errors.to_hash
      end
    end

    def validate_application
      if !@application.is_a?(Array)
        @errors.add(:application, :array, message: "must be an array")
      elsif !@application.all? {|a| a.is_a? String}
        @errors.add(:application, :array, message: "must be an array of strings")
      end
    end


    
  end
end
