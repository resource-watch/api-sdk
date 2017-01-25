require 'spec_helper'
require 'api_sdk'

RSpec.describe APISdk::Dataset do
  it "is not valid when empty" do
    dataset = APISdk::Dataset.new
    expect(dataset).to_not be_valid
  end
end
