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
      puts "ENDPOINT: ".red + "#{endpoint}"

      metadata = Array(metadata)

      ids = metadata.map do |md| {application: md.application, language: md.language } end
      puts("METADATA ARRAY: ".red + "#{metadata}")
      puts ("EXISTING METADATA IDS: ".red + "#{ids}")
      # Checks if the metadata for the language and application exists
      metadata_request = HTTParty.get(
        endpoint << "?page[number]=1&page[size]=10000",
        :headers => {
          "Authorization" => "Bearer #{token}",
          "Content-Type"  => "application/json"
        }
      )
      puts ("METADATA REQUEST: ".red + "#{metadata_request}")
      parsed_request = JSON.parse(metadata_request.parsed_response)
      puts ("PARSED REQUEST: ".red + "#{parsed_request}")
      existing_datasets = parsed_request["data"].map do |md|
        {application: md["attributes"]["application"], language: md["attributes"]["language"]}
      end
      puts("EXISTING DATASETS: ".red + "#{existing_datasets}")
      metadata_set_union =
        ids.map {|id| downcase_hash_values id} and existing_datasets.map {|id| downcase_hash_values id}
      puts("METADATA SET UNION: ".red + "#{metadata_set_union}")
      return metadata_request
    end

    private
    # To find set union with downcase values
    # h2.map {|h| downcase_hash_values h } - h1.map{|h| downcase_hash_values h}
    def self.downcase_hash_values(h)
      Hash[h.map{|k,v| v.class == Array ? [k,v.map{|r| downcase_hash_values r}.to_a] : [k,v.downcase]}]
    end
  end
end
