module APISdk
  class DatasetService
    # gfw_url will appropriately pull from ENV
    @@gfw_url     = ENV["GFW_API_URL"]
    @@dataset_url = "#{@@gfw_url}/dataset"
    
    def self.create(attrs, token)
      puts "ATTRIBUTES: ".red + "#{attrs}"
      puts "TOKEN: ".red + "#{token}"

      body = {
        # "dataset" => {
        #   "name"          => attrs[:name],
        #   "connectorType" => attrs[:connector_type],
        #   "provider"      => attrs[:provider],
        #   "application"   => attrs[:application],
        #   "connectorUrl"  => attrs[:connector_url],
        #   "subtitle"      => attrs[:subtitle],
        #   "dataPath"      => attrs[:data_path],
        #   "legend"        => attrs[:legend],
        #   "data"          => attrs[:data],
        #   "tableName"     => attrs[:table_name],
        #   "dataOverwrite" => attrs[:data_overwrite]
        # }.compact
        # #.delete_if {|k, v| v.nil?}.to_json # Removes nil keys
        "dataset" => Hash.new.tap do |dataset|
          dataset["name"] = attrs[:name]
          dataset["connectorType"] = attrs[:connector_type]
          dataset["provider"] = attrs[:provider]
          dataset["application"] = attrs[:application]
          dataset["connectorUrl"] = attrs[:connector_url]
          dataset["subtitle"] = attrs[:subtitle] if attrs[:subtitle]
          dataset["dataPath"] = attrs[:data_path] if attrs[:data_path]
          dataset["legend"] = attrs[:legend] if attrs[:legend]
          dataset["data"] = attrs[:data] if attrs[:data]
          dataset["tableName"] = attrs[:table_name] if attrs[:table_name]
          dataset["dataOverwrite"] = attrs[:data_overwrite] if attrs[:data_overwrite]
        end
      }.to_json
      puts "JSON BODY: ".red + "#{body}"
      
      request = HTTParty.post(
        @@dataset_url,
        :headers => {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{token}"
        },
        :body => body,
        :debug_output => $stdout
      )
      
      puts ("REQUEST: #{request}")
      return request
    end

    def self.read(dataset_id)
      request = HTTParty.get(
        "#{@@dataset_url}/#{dataset_id}?include=vocabulary"
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
