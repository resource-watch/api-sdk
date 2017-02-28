module APISdk
  class Layer
    include ActiveModel::Model
    include ActiveModel::Dirty
    extend  ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::AttributeMethods
    include ActiveModel::Serialization
    include ActiveModel::Serializers::JSON

    define_attribute_methods :name,
                             :description,
                             :application,
                             :layer_config,
                             :legend_config,
                             :application_config,
                             :static_image_config,
                             :iso,
                             :provider,
                             :default,
                             #
                             :metadata

    changeable_attr_accessor :name,
                             :description,
                             :application,
                             :layer_config,
                             :legend_config,
                             :application_config,
                             :static_image_config,
                             :iso,
                             :provider,
                             :default

    attr_accessor            :persisted,
                             :token,
                             :id,
                             :metadata

    validates :name, presence: true


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
        name:                @name,
        description:         @description,
        application:         @application,
        layer_config:        @layer_config,
        legend_config:       @legend_config,
        application_config:  @application_config,
        static_image_config: @static_image_config,
        iso:                 @iso,
        provider:            @provider,
        default:             @default,
      }
    end

    def persisted?
      @persisted ? self.id && !self.changed? : nil
    end

    # Reset the dataset to its initial state
    def rollback!
      restore_attributes
    end

    def self.find_for_dataset(dataset_id)
      puts "FINDING LAYERS FOR DATASET: ".red + "#{dataset_id}"
      layers_request = LayerService.read_at("dataset", dataset_id)
      layers_data = layers_request["data"]
      layers = []
      if not layers_data.empty?
        layers_data.each do |l|
          lyr = Layer.new(
            name:                l["attributes"]["name"],
            static_image_config: l["attributes"]["staticImageConfig"],
            application_config:  l["attributes"]["applicationConfig"],
            legend_config:       l["attributes"]["legendConfig"],
            layer_config:        l["attributes"]["layerConfig"],
            description:         l["attributes"]["description"],
            iso:                 l["attributes"]["iso"],
            provider:            l["attributes"]["provider"],
            default:             l["attributes"]["default"],
            application:         l["attributes"]["application"]
          )
          layers.append(lyr)
        end
      else
        puts "NO LAYERS FOR DATASET"
        return nil
      end
      return layers
    end
  end

  class LayerService
    def self.read_at(*route)
      endpoint = route.unshift(ENV["GFW_API_URL"]).push("layer").join("/")
      puts "LAYER ENDPOINT: ".red + "#{endpoint}"
      request = HTTParty.get(
        endpoint
      )
      puts "LAYERS REQUEST: ".red + "#{request}"
      return request.parsed_response
    end
  end
end
