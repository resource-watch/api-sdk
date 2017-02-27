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
                             :source_url,
                             :authors,
                             :query_url,
                             :widget_config,
                             :default,
                             :template,
                             :published,
                             :verified,
                             # Other fields,
                             :metadata

    changeable_attr_accessor :name,
                             :description,
                             :source_url,
                             :authors,
                             :query_url,
                             :widget_config,
                             :default,
                             :template,
                             :published,
                             :verified

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
  end

  class WidgetService
    def create
      nil
    end
  end
end
