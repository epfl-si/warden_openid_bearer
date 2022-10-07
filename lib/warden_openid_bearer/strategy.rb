# frozen_string_literal: true

require "jwt"

module WardenOpenidBearer
  # Like `WardenOpenidAuth::Strategy` in
  # `lib/warden_openid_auth/strategy.rb` from the `warden_openid_auth`
  # gem, except done right for a modern, split-backend Web application
  # (in which the browser takes charge of the OAuth2 login dance, and
  # the back-end only checks signatures on the JWT claims).
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

    def valid?
      return if !token
      # Do the issuer check here, so as to seamlessly support multiple
      # OIDC issuers inside the same app. If a token is not “for us”,
      # we want to defer to the other Warden strategy instances in the
      # stack (one which could typically be another instance of either
      # WardenOpenidBearer::Strategy, or one of its subclasses); therefore, we
      # want to return `false` if issuers don't match.
      untrusted_issuer == config.issuer
    end

    def authenticate!
      if (c = claims)
        success! user_of_claims(c)
      else
        # Given that `valid?` did return true previously,
        # we know the status with precision:
        fail! "Invalid OIDC bearer token"
      end
    rescue JWT::ExpiredSignature
      fail! "Expired OIDC bearer token"
    end

    # Overridden to always return false, because we typically *don't*
    # want persistent sessions for an OpenID-Connect resource server —
    # Everything we need to know is in the JWT token.
    def store?
      false
    end

    # Made public so that one may tune the `strategy.config.cache_timeout`:
    def config
      return @config if @config
      @config = WardenOpenidBearer::DiscoveredConfig.new(metadata_url)
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

    # Returns the JWT token from `request.headers['Authorization']`
    # (which may or may not be valid)
    def token
      # We call this one quite a lot, so we want some caching. Also,
      # it so happens that Warden only constructs a single instance of
      # this class and re-uses it across requests (see
      # `_fetch_strategy` in `lib/warden/proxy.rb`).
      cached_by(request) do
        puts request.headers
        strategy, token = (request.headers["Authorization"] || "").split(" ")
        token if (strategy || "").downcase == "bearer"
      end
    end

    # Returns the JWT claims, only if the cryptographic signature and
    # other security requirements (in particular, the expiration
    # timestamp) check out.
    def claims
      JWT.decode(token, nil, true, jwt_decode_opts).first
    end

    def jwt_decode_opts
      # Note: issuer check was already done in `valid?`, see
      # explanations there; skip it here.
      {
        algorithm: algorithm,
        verify_expiration: true,
        verify_not_before: true,
        verify_iat: true,
        jwks: config.jwks
      }
    end

    def algorithm
      return untrusted_algorithm if
          config.authorization_algs.member? untrusted_algorithm
    end

    def untrusted_fields
      JWT.decode(token, nil, false)
    end

    def untrusted_algorithm
      untrusted_fields.last["alg"]
    end

    def untrusted_issuer
      untrusted_fields.first["iss"]
    end
  end
end
