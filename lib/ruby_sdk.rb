class Dataset
  include ActiveModel::Model
  include ActiveModel::Serializations
  include ActiveModel::Associations

  CONNECTOR_TYPES     = %[document json rest]
  CONNECTOR_PROVIDERS = %[csv rwjson cartodb featureservice]

  attr_accessor :name, :connector_type, :connector_provider, :connector_url, :application

  def initialize(data = {})
    self.attributes = data unless data == {}
  end

  def attributes=(data)
  end

  def set_attributes(data)
  end

  #private
end
