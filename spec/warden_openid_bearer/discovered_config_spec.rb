RSpec.describe WardenOpenidBearer::DiscoveredConfig do
  it "lets you tweak the cache timeout" do
    config = WardenOpenidBearer::DiscoveredConfig.new("https://example.com/")
    config.cache_timeout = 444
    expect(config.cache_timeout).to eq(444)
  end

  it "is otherwise too simple to break" do
    _o_rly = "YA RLY"
  end
end
