# frozen_string_literal: true

require "json"
require "rack"
require "rack-rewrite"

class HttpServer
  def initialize
  end

  # def get_auth_token(req)
  #   token = req.get_header("HTTP_AUTHORIZATION") || "1-0"
  #   token.split("-")[1].to_i
  # end

  # def authorized?(req) # will be a UTC timestamp from sts service
  #   token = get_auth_token(req)
  #   now = Time.now.getutc.to_i
  #   token >= now
  # end

  def call(env)
    # req = Rack::Request.new(env)
    success_request("application/json", {message: "Hello World!"}.to_json)
  end

  def bad_request(code = 400, msg = "server error")
    [code, {"Content-Type" => "application/json"}, [msg]]
  end

  def unauthorized_request(msg = "unauthorized")
    bad_request(401, msg)
  end

  def success_request(mime, body)
    [200, {"Content-Type" => mime}, [body]]
  end

  def missing_resource(msg = "Resource not found")
    [404, {"Content-Type" => "application/json"}, [{message: msg}.to_json ]]
  end
end

run HttpServer.new

# use Rack::Rewrite do
#   # Respond to image downloads by sending to /image_store/[format]/[filename]
#   # using Rack::Static below
#   rewrite %r{/images/(.*?)/(.*?)\z}, lambda { |match, rack_env|
#     _x, format, filename = *match
#     "/image_store/#{format}/#{filename}"
#   }
# end

use Rack::Static, :urls => ["/images"], :root => "public",
  :header_rules => [
    [:all, {"Cache-Control" => "public, max-age=31536000"}],
  ]
