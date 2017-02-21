module APISdk
  class DatasetService
    # gfw_url will appropriately pull from ENV
    @@gfw_url     = "http://staging-api.globalforestwatch.org"
    @@dataset_url = "#{@@gfw_url}/dataset"
    
    def self.create(attrs, token)
      puts "ATTRIBUTES: #{attrs}"
      puts "TOKEN: #{token}"
      request = HTTParty.post(
        @@dataset_url,
        :headers => {"Authorization" => "Bearer #{token}"},
        :body => {
          "dataset" => {
            "name"          => attrs[:name],
            "connectorType" => attrs[:connector_type],
            "provider"      => attrs[:provider],
            "application"   => attrs[:application],
            "connectorUrl"  => attrs[:connector_url],
            "subtitle"      => attrs[:subtitle],
            "dataPath"      => attrs[:data_path],
            "legend"        => attrs[:legend],
            "data"          => attrs[:data],
            "tableName"     => attrs[:table_name],
            "dataOverwrite" => attrs[:data_overwrite]
          }.delete_if {|k, v| v.nil?} # Removes nil keys

        }
      )
      puts ("REQUEST: #{request}")
      return request
    end

    def self.read(dataset_id)
      request = HTTParty.get(
        "#{@@dataset_url}/#{dataset_id}?includes=vocabulary"
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
        :body => { "dataset" => params }
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
