RSpec.describe WardenOpenidBearer::Strategy do
  it "is good enough for Warden::Strategies" do
    stub_underscore("WardenOpenidBearer", "warden_openid_bearer")
    WardenOpenidBearer::Strategy.register!
  end

  it "lets you configure the metadata URL" do
    WardenOpenidBearer.configure do |config|
      config.openid_metadata_url = "https://example.com/"
    end
  end

  it "tokenizes" do
    def stub_request(strategy, authorization_header)
      request = double("request", {headers:
                                     {"Authorization" => authorization_header}})
      allow(strategy).to receive(:request).and_return(request)
    end

    strategy = WardenOpenidBearer::Strategy.new({})
    stub_request(strategy, "Bearer tototutu")
    expect(strategy.send(:token)).to eq("tototutu")
    stub_request(strategy, "Hocus Pocus")
    expect(strategy.send(:token)).to be_nil
  end
end
