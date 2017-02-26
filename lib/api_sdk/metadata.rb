module APISdk
  class Metadata
    include ActiveModel::Model
    include ActiveModel::Dirty
    extend  ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::AttributeMethods
    include ActiveModel::Serialization
    include ActiveModel::Serializers::JSON

    # METADATA FIELDS:
    #   application: <string>
    #   language: <string>
    #   name: <string>
    #   description: <string>
    #   source: <string>
    #   citation: <string>
    #   license: <string>
    #   info: <hash>
    #   units: <hash>
    
    define_attribute_methods :application,
                             :language,
                             :name,
                             :description,
                             :source,
                             :citation,
                             :license,
                             :info,
                             :units

    changeable_attr_accessor :name,
                             :description,
                             :source,
                             :citation,
                             :license,
                             :info,
                             :units

    attr_accessor :application,
                  :language


    def initialize(data = {})
      super
      @errors = ActiveModel::Errors.new(self)
      self.attributes = data unless data == {}
      # A new object is not persisted by default
      @persisted = false
      # And we reset the changes tracking
      clear_changes_information
    end

    def attributes=(data)
    end

    def attributes
      {
        application: @application,
        language:    @language,
        name:        @name,
        description: @description,
        source:      @source,
        citation:    @citation,
        license:     @license,
        info:        @info,
        units:       @units
      }
    end

    # Persistence tracking's got to be a little different for metadata
    def persisted?
      @persisted ? ((self.language and self.application) and !self.changed?) : false
    end

    # Reset the dataset to its initial state
    def rollback!
      restore_attributes
    end

    def create(token, endpoint)
      response = MetadataService.create(self.attributes, token, endpoint)
    end
    
    def update(token, endpoint)
      response = MetadataService.update(self.attributes, token, endpoint)
    end
  end

  class MetadataService
    def self.update_or_create(metadata, token, *ids)
      # The endpoint is constructed from the parameters:
      # An example call to get dataset metadata is:
      # MetadataService.update_or_create(self.metadata, self.token, "dataset", self.id)
      endpoint = ids.unshift(ENV["GFW_API_URL"]).push("metadata").join("/")
      puts "ENDPOINT: ".red + "#{endpoint}"
      # And metadata is put into an array if not already one
      metadata = Array(metadata)
      local_metadata = metadata.map do |md| {application: md.application, language: md.language } end
      puts ("LOCAL METADATA: ".red + "#{local_metadata}")
      # Checks if the metadata for the language and application exists
      endpoint_list = endpoint.dup
      metadata_request = HTTParty.get(
        endpoint_list << "?page[number]=1&page[size]=10000",
        :headers => {
          "Authorization" => "Bearer #{token}",
          "Content-Type"  => "application/json"
        }
      )
      parsed_request = JSON.parse(metadata_request.parsed_response)
      puts ("PARSED REQUEST: ".red + "#{parsed_request}")
      remote_metadata = parsed_request["data"].map do |md|
        {application: md["attributes"]["application"], language: md["attributes"]["language"]}
      end
      puts("REMOTE METADATA: ".red + "#{remote_metadata}")
      local_ids = local_metadata.map {|id| downcase_hash_values id}
      remote_ids = remote_metadata.map {|id| downcase_hash_values id}

      only_local_ids = local_ids - remote_ids
      puts("ONLY IN LOCAL: ".red + "#{only_local_ids}")
      # [{"a" => "b"}, {"a" => "c"}].any? {|h| h["a"] == "b"}
      orders = metadata.map do |md|
        puts [md.application, md.language]
        if only_local_ids.any? {|h| h[:application] == md.application.downcase and h[:language] == md.language.downcase}
          md.create(token, endpoint)
        else
          md.update(token, endpoint)
        end
      end

      
      return metadata_request
    end

    def self.create(attributes, token, endpoint)
      puts "Creating metadata #{self} at endpoint #{endpoint}"
    end

    def self.update(attributes, token, endpoint)
      puts "Updating metadata #{self} at endpoint #{endpoint}"
    end

    private
    # To find set union with downcase values
    # h2.map {|h| downcase_hash_values h } - h1.map{|h| downcase_hash_values h}
    def self.downcase_hash_values(h)
      Hash[h.map{|k,v| v.class == Array ? [k,v.map{|r| downcase_hash_values r}.to_a] : [k,v.downcase]}]
    end
  end
end
