# frozen_string_literal: true

require "dry/configurable"

require_relative "warden_openid_bearer/version"
require_relative "warden_openid_bearer/registerer"

module WardenOpenidBearer
  extend Dry::Configurable

  setting :openid_metadata_url, constructor: ->(url) { URI(url) }
end
