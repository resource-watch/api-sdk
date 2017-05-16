Gem::Specification.new do |s|
  s.name        = 'rw_api_sdk'
  s.version     = '0.2.0'
  s.licenses    = ['MIT']
  s.summary     = "Interfaces a ruby applications to the Resource Watch api"
  s.description = "Not yet"
  s.authors     = ["Enrique Cornejo"]
  s.email       = 'enrique@cornejo.me'
  s.files       = [
    "lib/rw_api_sdk.rb",
    "lib/rw_api_sdk/dataset_service.rb",
    "lib/rw_api_sdk/widget.rb",
    "lib/rw_api_sdk/layer.rb",
    "lib/rw_api_sdk/vocabulary.rb",
    "lib/rw_api_sdk/metadata.rb",
    "lib/rw_api_sdk/attr_changeable_methods.rb"
  ]
  s.homepage    = 'https://www.vizzuality.com'
  s.add_runtime_dependency "activemodel", "~> 5.1"
  s.add_runtime_dependency "activerecord", "~> 5.1"
  s.add_runtime_dependency "activesupport", "~> 5.1"
  s.add_runtime_dependency "httparty", "~> 0.15"
  s.add_runtime_dependency "colorize", "~> 0.8"
end
