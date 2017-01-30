# Declaring the changeable_attr_accessor for later
# Must move from here to its own file
class Class
  # Custom accessor with support for dirty objects
  def changeable_attr_accessor(*args)
    args.each do |arg|
      # getter
      self.class_eval("def #{arg};@#{arg};end")
      # setter
      self.class_eval("def #{arg}=(val);#{arg}_will_change! unless val==@#{arg};@#{arg}=val;end")
    end
  end
end


module APISdk
  class DatasetService
    # gfw_url will appropriately pull from ENV
    @@gfw_url     = "http://staging-api.globalforestwatch.org"
    @@dataset_url = "#{@@gfw_url}/dataset"
    
    def self.create(params, token)
      puts "PARAMS: #{params}"
      puts "TOKEN: #{token}"
      request = HTTParty.post(
        @@dataset_url,
        :headers => {"Authorization" => "Bearer #{token}"},
        :query => {
          "dataset" => {
            "name"          => params[:name],
            "connectorType" => params[:connector_type],
            "provider"      => params[:provider],
            "application"   => params[:application],
            "connectorUrl"  => params[:connector_url]
          }
        }
      )
      puts ("REQUEST: #{request}")
      return request
    end

    def self.read(dataset_id)
      request = HTTParty.get(
        "#{@@dataset_url}/#{dataset_id}"
      )
      puts("REQUEST: #{request}")
      return request
    end


    def self.update(dataset_id, params, token)
      puts "PARAMS: #{params}"
      puts "TOKEN: #{token}"
      request = HTTParty.put(
        "#{@@dataset_url}/#{dataset_id}",
        :headers => {"Authorization" => "Bearer #{token}"},
        :query => { "dataset" => params }
      )
      puts ("REQUEST: #{request}")
      return request
    end

    def self.delete(dataset_id, token)
      puts "TOKEN: #{token}"
      request = HTTParty.delete(
        "#{@@dataset_url}/#{dataset_id}",
        :headers => {"Authorization" => "Bearer #{token}"}
      )
      puts ("REQUEST: #{request}")
      return request
    end
    
    def self.check_logged(dataset)
      token = dataset.token
      request = HTTParty.get(
        "#{@@gfw_url}/auth/check-logged",
        :headers => {"Authorization" => "Bearer #{token}"}
      )
      puts ("REQUEST: #{request}")
      return request
    end
  end
end
