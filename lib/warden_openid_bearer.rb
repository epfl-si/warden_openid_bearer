# frozen_string_literal: true

require "dry/configurable"
require "openssl"
require "uri"

require_relative "warden_openid_bearer/version"
require_relative "warden_openid_bearer/registerer"
require_relative "warden_openid_bearer/cache_mixin"
require_relative "warden_openid_bearer/discovered_config"
require_relative "warden_openid_bearer/strategy"

module WardenOpenidBearer
  extend Dry::Configurable

  setting :openid_metadata_url, constructor: ->(url) { URI(url) }
  setting :openid_server_certificate, default: nil, constructor: ->(pem) { if pem; OpenSSL::X509::Certificate.new(pem); else nil; end }
  setting :cache_timeout, default: 900
end
