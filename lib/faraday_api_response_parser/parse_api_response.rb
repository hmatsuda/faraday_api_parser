module FaradayApiResponseParser
  class UnauthorizedError < StandardError; end
  class ForbiddenError < StandardError; end
  class NotFoundError < StandardError; end
  class InternalServerError < StandardError; end
  class ServiceUnavailableError < StandardError; end
  
  class ParseApiResponse < ::Faraday::Response::Middleware
    def call(request_env)
      @app.call(request_env).on_complete do |response_env|
        rawdata = response_env[:body]
        json = MultiJson.load(response_env[:body], symbolize_keys: true)

        case response_env[:status]
        when 200,201,204
          response_env[:body] = {
            data: json,
            errors: [],
            metadata: {
              response_headers: response_env.response_headers,
              rawdata: rawdata,
            }
          }
          
          if json.class == Array
            json.each do |resource|
              convert_datetime_attributes(resource)
            end
          elsif json.class == Hash
            convert_datetime_attributes(json)
          end
        when 400
          response_env[:body] = {
            data: {},
            errors: json[:errors],
            metadata: {}
          }
        when 401
          raise FaradayApiResponseParser::UnauthorizedError
        when 403
          raise FaradayApiResponseParser::ForbiddenError
        when 404
          raise FaradayApiResponseParser::NotFoundError
        when 500
          raise FaradayApiResponseParser::InternalServerError
        when 500
          raise FaradayApiResponseParser::ServiceUnavailableError
        end
      end
    end

    def convert_datetime_attributes(resource)
      resource.keys.select{|k,v| k =~ /(_date|_at|period)$/}.each do |attribute|
        if resource[attribute].respond_to?(:to_time)
          resource[attribute] = \
            begin
              resource[attribute].to_time 
            rescue ArgumentError => e
              nil
            end
        end
      end
    end
  end
end
