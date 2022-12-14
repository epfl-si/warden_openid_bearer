# frozen_string_literal: true

require "warden_openid_bearer"
# require "debug"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def stub_underscore(from, to)
  allow_any_instance_of(String).to receive(:underscore) do |that|
    expect(that).to eq(from)
    to
  end
end
