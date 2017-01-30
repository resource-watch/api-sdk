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
    
    # FARADAY. TO BE REMOVED.
    @conn ||= Faraday.new(:url => "http://staging-api.globalforestwatch.org") do |faraday|
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

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
    
    # def self.delete(dataset_id, token)
    #   request = @conn.delete do |req|
    #     req.url "/dataset/#{dataset_id}"
    #     req.headers['Content-Type'] = 'application/json'
    #     req.headers['Authorization'] = "Bearer #{token}"
    #   end
    #   if request.status == 200
    #     result = JSON.parse request.body
    #     puts(result)
    #     # Poor man's symbolize_keys!
    #     return {status: request.status, dataset_parameters: result}
    #   else
    #     return {status: request.status, dataset_parameters: nil}
    #   end
    # end

    def self.check_logged(dataset)
      token = dataset.token
      request = @conn.get do |req|
        req.url "/auth/check-logged"
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{token}"
      end
      puts("HEADERS: #{request.headers}")
      puts("BODY: #{request.body}")
    end

    def self.check_logged_without_token(dataset)
      request = @conn.get do |req|
        req.url "/auth/check-logged"
        req.headers['Content-Type'] = 'application/json'
      end
      puts("HEADERS: #{request.headers}")
      puts("BODY: #{request.body}")
    end

  end
end
