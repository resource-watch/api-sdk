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
    # For now targeting my dev server
    #@conn ||= Faraday.new(:url => ENV.fetch("API_URL")) do |faraday|
    @conn ||= Faraday.new(:url => "http://staging-api.globalforestwatch.org") do |faraday|
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    def self.create(params)
      puts "PARAMS: #{}"
      request = @conn.post do |req|
        req.url "/dataset/"
        req.headers['Content-Type'] = 'application/json'
        req.body = params.to_json
      end
      if request.status == 201
        result = JSON.parse request.body
        data = result["data"]
        # Poor man's symbolize_keys!
        data.keys.each do |key|
          data[(key.to_sym rescue key) || key] = data.delete(key)
        end
        return {status: request.status, dataset_parameters: data}
      else
        return {status: request.status, dataset_parameters: nil}
      end
      
    end
    
    def self.read(dataset_id)
      request = @conn.get do |req|
        req.url "/dataset/#{dataset_id}"
        req.headers['Content-Type'] = 'application/json'
      end
      if request.status == 200
        result = JSON.parse request.body
        data = result["data"]
        puts(data)
        # Poor man's symbolize_keys!
        data.keys.each do |key|
          data[(key.to_sym rescue key) || key] = data.delete(key)
        end
        return {status: request.status, dataset_parameters: data}
      else
        return {status: request.status, dataset_parameters: nil}
      end
    end

    def self.update(dataset_id, params)
      request = @conn.put do |req|
        req.url "/dataset/#{dataset_id}"
        req.headers['Content-Type'] = 'application/json'
        req.body = params.to_json
      end
      if request.status == 200
        result = JSON.parse request.body
        data = result["data"]
        puts("DATA: #{data}")
        # Poor man's symbolize_keys!
        data.keys.each do |key|
          data[(key.to_sym rescue key) || key] = data.delete(key)
        end
        puts("SYMBOLIZED DATA: #{data}")
        # API always returns in camelCase, doesn't it?
        return {status: request.status, dataset: data}
      else
        return {status: request.status, dataset: nil}
      end
    end

    def self.delete(dataset_id)
      request = @conn.delete do |req|
        req.url "/dataset/#{dataset_id}"
        req.headers['Content-Type'] = 'application/json'
      end
      if request.status == 200
        result = JSON.parse request.body
        puts(result)
        # Poor man's symbolize_keys!
        return {status: request.status, dataset_parameters: result}
      else
        return {status: request.status, dataset_parameters: nil}
      end
    end

    def self.check_logged(dataset)
      token = dataset.user_token

      request = @conn.get do |req|
        req.url "/auth/check-logged"
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{token}"
      end
      puts("HEADERS: #{request.headers}")
      puts("BODY: #{request.body}")
    end
  end
end
