# frozen_string_literal: true

require_relative "lib/warden_openid_bearer/version"

Gem::Specification.new do |spec|
  spec.name = "warden_openid_bearer"
  spec.version = WardenOpenidBearer::VERSION
  spec.authors = ["Dominique Quatravaux"]
  spec.email = ["dominique.quatravaux@epfl.ch"]

  spec.summary = "Warden strategy to validate OpenID-Connect bearer tokens"
  spec.description = <<~END_DESCRIPTION

    This gem is like the `warden_openid_auth` gem, except that it only
    provides support for the very last step of the OAuth code flow, i.e.
    when the resource server / relying party (your Ruby Web app)
    validates and decodes the JWT token.

    Use this gem if your client-side Web (or mobile) app will be taking
    care of the rest of the OAuth2 motions, such as redirecting (or
    opening a popup window) to the authentication server at login time,
    managing and refreshing tokens, doing all these unspeakable things
    with iframes, etc.

  END_DESCRIPTION
  spec.homepage = "https://github.com/epfl-si/warden_openid_bearer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["my_side_project_has_a_side_project"] = "https://github.com/epfl-si/rails.starterkit"

  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-configurable", "~> 0.15.0"
end
