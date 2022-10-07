# frozen_string_literal: true

require "net/http"

module WardenOpenidBearer
  # Cacheable configuration (periodically re-)fetched starting from
  # the OpenID authentication server's “well-known” endpoint
  class DiscoveredConfig
    include CacheMixin

    def initialize(metadata_uri)
      @metadata_uri = metadata_uri
    end

    # Called by the CacheMixin.
    def cache_timeout
      @cache_timeout ||= 900
    end
    # Provide a public API for tuning the timeout.
    attr_writer :cache_timeout

    def jwks
      json(metadata[:jwks_uri])
    end

    def issuer
      metadata[:issuer]
    end

    def authorization_algs
      metadata[:authorization_signing_alg_values_supported]
    end

    private

    def metadata
      json(@metadata_uri)
    end

    def json(uri)
      cached_by(uri) do
        JSON.parse(Net::HTTP.get_response(URI(uri)).body, symbolize_names: true)
      end
    end
  end
end
