require 'spec_helper'
require 'controltower'

RSpec.describe ControlTower::Dataset do
  it "is not valid when empty" do
    dataset = ControlTower::Dataset.new
    expect(dataset).to_not be_valid
  end
end
