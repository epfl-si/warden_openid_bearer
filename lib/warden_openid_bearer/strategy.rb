# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'warden_openid_bearer/net_https'

module WardenOpenidBearer
  # Like `WardenOpenidAuth::Strategy` in
  # `lib/warden_openid_auth/strategy.rb` from the `warden_openid_auth`
  # gem, except done right for a modern, split-backend Web application
  # (in which the browser takes charge of the OAuth2 login dance, and
  # the back-end only validates bearer tokens).
  #
  # You shoud subclass `WardenOpenidBearer::Strategy` and override the
  # `user_of_claims` protected method if you want `env['warden'].user`
  # to be a “real” user object (instead of just a hash of OIDC claims,
  # which is what happens when using `WardenOpenidBearer::Strategy` directly).
  # If you want your Rails app to support more than one OIDC
  # authentication server, you should also subclass
  # `WardenOpenidBearer::Strategy` and override the `metadata_url` method.
  #
  # This class has a `self.register!` method, which makes things
  # (slightly) easier than calling `Warden::Strategies.add` yourself.
  # See `WardenOpenidBearer::Registerer` for details.
  class Strategy < Warden::Strategies::Base
    include WardenOpenidBearer::Registerer # Provides self.register!
    include WardenOpenidBearer::CacheMixin

    # Override in a subclass to support multiple authentication
    # servers (if tokens can be discriminated between them somehow).
    # The base class returns True whenever an `Authentication: Bearer`
    # request header is present.
    def valid?
      !!token
    end

    def authenticate!
      res = oauth2_userinfo_response
      body = res.body

      if res.is_a?(Net::HTTPSuccess)
        success! user_of_claims(JSON.parse(body))
      else
        fail! body
      end
    end

    # Overridden to always return false, because we typically *don't*
    # want persistent sessions for an OpenID-Connect resource server —
    # If we cached, we would break logout.
    def store?
      false
    end

    # Made public so that one may tune the `strategy.config.cache_timeout`:
    def config
      return @config if @config

      @config = WardenOpenidBearer::DiscoveredConfig.new(metadata_url)
      if (peer_cert = WardenOpenidBearer.config.openid_server_certificate)
        @config.peer_cert = peer_cert
      end

      @config.cache_timeout = cache_timeout
      @config
    end

    protected

    # Dummy implementation for applications that don't really care
    # about `env['warden'].user` being an object (or at all). Override
    # in a subclass if you do care.
    def user_of_claims(claims)
      claims
    end

    # Returns the URL of the OIDC metadata for the authentication server,
    # which typically ends with `/.well-known/openid-configuration`
    #
    # The default implementation obeys the `.openid_metadata_url`
    # setting, as set in a `WardenOpenidBearer.configure` block. Override
    # in a subclass if you don't want all your OIDC claims to be
    # checked against one and the same authentication server. (If you
    # want to support two authentication servers, for instance, you
    # should have two subclasses.)
    def metadata_url
      WardenOpenidBearer.config.openid_metadata_url
    end

    # Returns the cache timeout for the security data obtained from
    # the authentication server.
    #
    # The default implementation uses a global configuration. Like
    # `metadata_url`, you should override this in multiple subclasses
    # if you want multiple OpenID authentication servers.
    def cache_timeout
      WardenOpenidBearer.config.cache_timeout
    end

    # Returns the bearer token from `request.headers['Authorization']`
    # (which may or may not be valid)
    def token
      # We call this one quite a lot, so we want some caching. Also,
      # it so happens that Warden only constructs a single instance of
      # this class and re-uses it across requests (see
      # `_fetch_strategy` in `lib/warden/proxy.rb`).
      cached_by(request) do
        strategy, token = (request.headers["Authorization"] || "").split(" ")
        token if (strategy || "").downcase == "bearer"
      end
    end

    def oauth2_userinfo_response
      cached_by(request) do
        _do_oauth2_userinfo
      end
    end

    def _do_oauth2_userinfo
      uri = URI.parse(config.userinfo_endpoint)
      req = Net::HTTP::Get.new(uri)
      req['Authorization'] = "Bearer #{token}"

      if uri.scheme == 'https'
        http = WardenOpenidBearer::NetHTTPS.new(uri.hostname, uri.port)
        if (peer_cert = WardenOpenidBearer.config.openid_server_certificate)
          http.peer_cert = peer_cert
        end
      else
        http = Net::HTTP.new(uri.hostname, uri.port)
      end
      http.start do |http|
        http.request(req)
      end
    end
  end
end
