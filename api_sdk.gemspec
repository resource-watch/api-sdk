Gem::Specification.new do |s|
  s.name        = 'api_sdk'
  s.version     = '0.0.151'
  s.licenses    = ['MIT']
  s.summary     = "Interfaces a ruby applications to the Resource Watch api"
  s.description = "Not yet"
  s.authors     = ["Enrique Cornejo"]
  s.email       = 'enrique@cornejo.me'
  s.files       = ["lib/api_sdk.rb", "lib/api_sdk/dataset_service.rb"]
  s.homepage    = 'https://www.vizzuality.com'
  s.add_runtime_dependency "activemodel"
  s.add_runtime_dependency "activerecord"
  s.add_runtime_dependency "faraday"
end
