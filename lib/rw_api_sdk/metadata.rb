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
                  :language,
                  :id


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
      attrs_without_ids = self.attributes.compact
      changed_parameters = self.changes.map {|k,v| {k =>  v.last}}.reduce(:merge)
      attributes = [
        changed_parameters,
        {application: self.application},
        {language: self.language}
      ].reduce(:merge)
      response = MetadataService.update(attributes, token, endpoint)
    end

    def self.find(*route)
      response = MetadataService.read(*route)
      puts "UNO".red
      puts response.parsed_response
      puts response.parsed_response.to_json
      puts "DOS".red
      parsed_response = JSON.parse(response.parsed_response.to_json)
      puts "DATASET METADATA PARSED RESPONSE: ".red
      puts "-- route: ".red + "#{route}"
      puts "-- response: ".red + "#{parsed_response}"
      if parsed_response["data"].any?
        data = parsed_response["data"]
        metadata = data.map do |attrs|
          md = Metadata.new(
            application: attrs["attributes"]["application"],
            language: attrs["attributes"]["language"],
            name: attrs["attributes"]["name"],
            description: attrs["attributes"]["description"],
            source: attrs["attributes"]["source"],
            citation: attrs["attributes"]["citation"],
            license: attrs["attributes"]["license"],
            info: attrs["attributes"]["info"],
            units: attrs["attributes"]["units"]
          )
          md.id = attrs["id"]
          md
        end
        puts "DATASET METADATA: ".red + "#{metadata}"
        return metadata
      else
        puts "NO METADATA AT ENDPOINT".yellow
        return nil
      end
    end
  end

  class MetadataService
    def self.read(*route)
      endpoint = route.unshift(ENV["GFW_API_URL"]).push("metadata").join("/")
      puts "FINDING DATASET METADATA AT ENDPOINT: ".red + "#{endpoint}"
      endpoint_no_pagination = endpoint.dup << "?page[number]=1&page[size]=10000"
      metadata_request = HTTParty.get(
        endpoint_no_pagination,
        :headers => {
          "Content-Type"  => "application/json"
        }
      )
      puts "METADATA REQUEST: ".red + "#{metadata_request}"
      return metadata_request
    end

    def self.update_or_create(metadata, token, *ids)
      # The endpoint is constructed from the parameters:
      # An example call to get dataset metadata is:
      # MetadataService.update_or_create(self.metadata, self.token, "dataset", self.id)
      endpoint = ids.unshift(ENV["GFW_API_URL"]).push("metadata").join("/")
      endpoint_no_pagination = endpoint.dup << "?page[number]=1&page[size]=10000"
      puts "Checking metadata at endpoint: ".red + "#{endpoint_no_pagination}"
      # And metadata is put into an array if not already one
      metadata = Array(metadata)
      local_metadata = metadata.map do |md|
        {application: md.application, language: md.language }
      end
      puts ("Local keys: ".red + "#{local_metadata}")
      # Checks if the metadata for the language and application exists
      metadata_request = HTTParty.get(
        endpoint_no_pagination,
        :headers => {
          "Authorization" => "Bearer #{token}",
          "Content-Type"  => "application/json"
        }
      )
      parsed_request = JSON.parse(metadata_request.parsed_response)
      puts ("Parsed request: ".red + "#{parsed_request}")
      remote_metadata = parsed_request["data"].map do |md|
        {
          application: md["attributes"]["application"],
          language: md["attributes"]["language"]
        }
      end
      puts("Remote metadata keys: ".red + "#{remote_metadata}")
      local_ids = local_metadata.map {|id| downcase_hash_values id}
      remote_ids = remote_metadata.map {|id| downcase_hash_values id}
      only_local_ids = local_ids - remote_ids
      puts("Local only metadata keys: ".red + "#{only_local_ids}")
      # [{"a" => "b"}, {"a" => "c"}].any? {|h| h["a"] == "b"}
      puts "Creating metadata".red

      metadata.each do |md|
        keys = {
          application: md.application.downcase,
          language:    md.language.downcase
        }
        if only_local_ids.include? keys
          puts "Creating metadata with application #{md.application} and language #{md.language} \n at endpoint #{endpoint}"
          md.create(token, endpoint)
        elsif remote_ids.include? keys
          puts "Looking for changes in metadata with application #{md.application} and language #{md.language} \n at endpoint #{endpoint}"
          if md.changes.any?
            puts "-- Changes found. Updating metadata."
            md.update(token, endpoint)
          else
            puts "-- No changes found. Skipping."
          end
        else
          puts "?"
        end
      end
      return nil
    end
    
    def self.create(attributes, token, endpoint)
      attributes_json = attributes.compact.to_json
      puts "ATTRIBUTES JSON: ".red + "#{attributes_json}"
      request = HTTParty.post(
        endpoint,
        :headers => {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{token}"
        },
        :body => attributes_json,
        :debug_output => $stdout
      )

      puts "REQUEST: " + "#{request}"
      return request
    end

    def self.update(attributes, token, endpoint)
      attributes_json = attributes.to_json
      puts "ATTRIBUTES JSON: ".red + "#{attributes_json}"
      request = HTTParty.patch(
        endpoint,
        :headers => {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{token}"
        },
        :body => attributes_json,
        :debug_output => $stdout
      )
      
      puts "REQUEST: " + "#{request}"
      return request
    end

    private

    # To find set union with downcase values
    # h2.map {|h| downcase_hash_values h } - h1.map{|h| downcase_hash_values h}
    def self.downcase_hash_values(h)
      Hash[h.map{|k,v| v.class == Array ? [k,v.map{|r| downcase_hash_values r}.to_a] : [k,v.downcase]}]
    end
  end
end
