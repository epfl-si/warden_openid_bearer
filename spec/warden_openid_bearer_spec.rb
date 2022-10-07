# frozen_string_literal: true

RSpec.describe WardenOpenidBearer do
  it "has a version number" do
    expect(WardenOpenidBearer::VERSION).not_to be nil
  end

  it "can be configured" do
    WardenOpenidBearer.configure do |config|
      config.openid_metadata_url = "https://example.com/"
    end
  end
end
