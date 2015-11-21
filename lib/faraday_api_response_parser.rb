require "faraday_api_response_parser/version"
require "faraday"

module FaradayApiResponseParser
  autoload :ParseApiResponse, "faraday_api_response_parser/parse_api_response"

  Faraday::Response.register_middleware(
    api_response: -> { ParseApiResponse },
  )
end
