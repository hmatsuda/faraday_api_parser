module FaradayApiResponseParser
  class ParseApiResponse < ::Faraday::Response::Middleware
    def call(env)
      @app.call(env).on_complete do |env|
        json = MultiJson.load(env[:body], symbolize_keys: true)

        case env[:status]
        when 200,201,204
          env[:body] = {
            data: json,
            errors: [],
            metadata: {}
          }
          
          if json.class == Array
            json.each do |resource|
              convert_datetime_attributes(resource)
            end
          elsif json.class == Hash
            convert_datetime_attributes(json)
          end
        when 400
          env[:body] = {
            data: {},
            errors: json[:errors],
            metadata: {}
          }
        when 401
          raise StandardError
        when 403
        when 404
          raise StandardError
        when 500
          raise StandardError
        end
      end

      def convert_datetime_attributes(resource)
      resource.keys.select{|k,v| k =~ /(_date|_at|period)$/}.each do |attribute|
        if resource[attribute].respond_to?(:to_time)
          resource[attribute] = begin
            resource[attribute].to_time 
          rescue ArgumentError => e
            nil
          end
        end
      end
    end
  end
end
