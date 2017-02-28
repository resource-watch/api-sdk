module APISdk
  class Widget
    include ActiveModel::Model
    include ActiveModel::Dirty
    extend  ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::AttributeMethods
    include ActiveModel::Serialization
    include ActiveModel::Serializers::JSON

    define_attribute_methods :name,
                             :description,
                             :source,
                             :source_url,
                             :authors,
                             :query_url,
                             :widget_config,
                             :default,
                             :template,
                             :published,
                             :verified,
                             :template,
                             :default,
                             # Other fields,
                             :metadata

    changeable_attr_accessor :name,
                             :description,
                             :source,
                             :source_url,
                             :authors,
                             :query_url,
                             :widget_config,
                             :default,
                             :template,
                             :published,
                             :verified,
                             :template,
                             :default

    attr_accessor            :persisted,
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
        name:          @name,
        description:   @descripion,
        source_url:    @source_url,
        authors:       @authors,
        query_url:     @query_url,
        widget_config: @widget_config,
        default:       @default,
        template:      @template,
        published:     @published,
        verified:      @verified
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
      puts "FINDING WIDGETS FOR DATASET: ".red + "#{dataset_id}"
      widgets_request = WidgetService.read_at("dataset", dataset_id)
      widgets_data = widgets_request["data"]
      widgets = []
      if not widgets_data.empty?
        widgets_data.each do |w|
          wdgt = Widget.new(
            name:          w["attributes"]["name"],
            description:   w["attributes"]["description"],
            source_url:    w["attributes"]["source_url"],
            authors:       w["attributes"]["authors"],
            query_url:     w["attributes"]["query_url"],
            widget_config: w["attributes"]["widget_config"],
            default:       w["attributes"]["default"],
            template:      w["attributes"]["template"],
            published:     w["attributes"]["published"],
            verified:      w["attributes"]["verified"]
          )
          wdgt.id = w["id"]
          widgets.append(wdgt)
        end
      else
        puts "NO WIDGETS FOR DATASET"
        return nil
      end
      return widgets
    end
  end

  class WidgetService
    def self.read_at(*route)
      endpoint = route.unshift(ENV["GFW_API_URL"]).push("widget").join("/")
      puts "WIDGETS ENDPOINT: ".red + "#{endpoint}"
      request = HTTParty.get(
        endpoint
      )
      puts "WIDGETS REQUEST: ".red + "#{request}"
      return request.parsed_response
    end
  end
end
