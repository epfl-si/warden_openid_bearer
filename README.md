# WardenOpenidBearer

[Warden](https://github.com/wardencommunity/warden) strategy for authentication with OpenID-Connect bearer tokens.

This gem is like
[the `warden_openid_auth gem`](https://rubygems.org/gems/warden_openid_auth),
except that it only provides support for the very last step of
the OAuth code flow, i.e. when the resource server / relying party
(your Ruby Web app) validates and decodes the bearer token.

Use this gem if your client-side Web (or mobile) app will be taking
care of the rest of the OAuth2 motions, such as redirecting (or
opening a popup window) to the authentication server at login time,
managing and refreshing tokens, doing all these unspeakable things
with iframes, etc.

## Usage

### In a Rails application


1. Add the [`rails_warden` gem](https://rubygems.org/gems/rails_warden) into your application
1. Add the following to e.g. `config/initializers/authentication.rb`:
   ```ruby
   Rails.application.config.middleware.use RailsWarden::Manager do |manager|
     manager.default_strategies WardenOpenidBearer::Strategy.register!
     WardenOpenidBearer.configure do |oidc|
       oidc.openid_metadata_url = "https://example.com/.well-known/openid-configuration"
       oidc.scope = ["openid", "email"]
       oidc.redirect_uri = ["openid", "email"]
       # Optional — Explicit OpenID-Connect server certificate (e.g. for a development rig):
       oidc.openid_server_certificate = <<-CERT
   -----BEGIN CERTIFICATE-----
   MIIDCTBLAHBLAHBLAH==
   -----END CERTIFICATE-----
   CERT
     end
   
     manager.failure_app = Proc.new { |_env|
       ['401', {'Content-Type' => 'application/json'}, [{ error: 'Unauthorized' }.to_json]]
     }
   end
   ```
1. Access control must be explicitly added to your controllers, e.g.
   ```ruby
   class MyController < ApplicationController
     before_action do
       authenticate!
     end
   end
   ```
   
### Subclassing

Subclassing `WardenOpenidBearer::Strategy` is the recommended way to
- support more than one authentication server (overriding `valid?`, `metadata_url` and/or `cache_timeout`),
- provide user hydration into the class of your choice (overriding `user_of_claims`).

More details available in the rubydoc comments of
[`lib/warden_openid_bearer/strategy.rb`](lib/warden_openid_bearer/strategy.rb).

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add warden_openid_bearer

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install warden_openid_bearer

## Development

After checking out the Git repository, run `bin/setup` to install dependencies. Then, run `bundle exec rake` to run the test suite and linter checks. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Debugger

The `debugger` gem is a development-time requirement (in the Gemfile). In order to activate it:

1. Uncomment the line that says `require "debug"` in `./spec/spec_helper.rb`
1. Stick `debugger` somewhere in the source or test code
1. Run the test suite

### Local Install

To install this gem onto your local machine, run `bundle exec rake install`.

### Release

To release a new version:
1. Make sure that the version you want to publish is the current `master` branch on GitHub, and that the tests are green
1. Check out the `master` branch in your working directory
1. Update the version number in `version.rb`
1. Run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/epfl-si/warden_openid_bearer .

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
