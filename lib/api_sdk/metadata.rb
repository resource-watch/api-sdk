module APISdk
  class Metadata
    include ActiveModel::Model
    include ActiveModel::Dirty
    extend  ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::AttributeMethods
    include ActiveModel::Serialization
    include ActiveModel::Serializers::JSON

    define_attribute_methods :application,
                             :language

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
        language:    @language
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
  end

  class MetadataService
    def self.update_or_create(metadata, token, *ids)
      endpoint = ids.unshift(ENV["GFW_API_URL"]).push("metadata").join("/")
      puts "ENDPOINT: #{endpoint}"

      # Checks if the metadata for the language and application exists
      request = HTTParty.get(
        endpoint << "?page[number]=1&page[size]=10000",
        :headers => {
          "Authorization" => "Bearer #{token}",
          "Content-Type"  => "application/json"
        }
      )
      puts ("METADATA REQUEST: #{request}")
      parsed_request = JSON.parse(request.parsed_response)
      puts ("PARSED REQUEST: #{parsed_request}")
      existing_datasets = parsed_request["data"].map do |md|
        {application: md["attributes"]["application"], language: md["attributes"]["language"]}
      end
      puts("Existing datasets: #{existing_datasets}")
      puts "let's see"
      return request
    end
  end
end
