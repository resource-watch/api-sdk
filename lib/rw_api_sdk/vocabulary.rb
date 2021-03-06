module APISdk
  class Vocabulary
    include ActiveModel::Model
    include ActiveModel::Dirty
    extend  ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::AttributeMethods
    include ActiveModel::Serialization
    include ActiveModel::Serializers::JSON

    define_attribute_methods :name,
                             :tags

    changeable_attr_accessor :name,
                             :tags

    attr_accessor            :id
    
    validates :name, presence: true
    validate :validate_tags


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
        name: @name,
        tags: @tags
      }
    end

    def persisted?
      @persisted ? self.id && !self.changed? : nil
    end

    # Reset the dataset to its initial state
    def rollback!
      restore_attributes
    end

    # Finds a vocabulary by its id. TODO
    def self.find(vocabulary_id)
    end

    # Updates a vocabulary
    def self.update(vocabulary_id, params, token)
      puts "PARAMS: #{params}"
      puts "TOKEN: #{token}"
      request = HTTParty.put(
        "#{@@vocabulary_url}/#{vocabulary_id}",
        :headers => {"Authorization" => "Bearer #{token}"},
        :body => { "vocabulary" => params }
      )
      puts ("REQUEST: #{request}")
      return request
    end

    private

    def validate_tags
      if @tags.nil?
        @errors.add(:tags, :nil, message: "Tags can't be nil")
      elsif !@tags.is_a?(Array)
        @errors.add(:tags, :not_an_array, message: "Tags must be an array")
      elsif @tags == []
        @errors.add(:tags, :is_empty_array, message: "Tags can't be an empty array")
      elsif !@tags.all? {|el| el.is_a? String}
        @errors.add(:tags, :not_strings_array, message: "Tags must be a string array")
      end
    end
  end

  class VocabularyService
    @@gfw_url     = "http://staging-api.globalforestwatch.org"
    @@vocabulary_url = "#{@@gfw_url}/vocabulary"
    
    def self.read_vocabularies(dataset_id)
      request = HTTParty.get(
        "#{@@gfw_url}/dataset/#{dataset_id}/vocabulary",
        :headers => {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{}"
        },
        format: :json
      )
      puts("VOCAB REQUEST: #{request}")
      return request
    end
  end
end
    
