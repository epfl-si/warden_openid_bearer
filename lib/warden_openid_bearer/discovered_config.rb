# frozen_string_literal: true

require 'warden_openid_bearer/net_https'

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

    def userinfo_endpoint
      metadata[:userinfo_endpoint]
    end

    def peer_cert=(peer_cert)
      @peer_cert = peer_cert
    end

    private

    def metadata
      json(@metadata_uri)
    end

    def json(uri)
      cached_by(uri) do
        response = WardenOpenidBearer::NetHTTPS.get_response(URI(uri), @peer_cert)
        JSON.parse(response.body, symbolize_names: true)
      end
    end
  end
end
