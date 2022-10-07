# frozen_string_literal: true

RSpec.describe WardenOpenidBearer::Registerer do
  it "registers" do
    module My # standard:disable Lint/ConstantDefinitionInBlock
      module Weird
        class Strategy
          include WardenOpenidBearer::Registerer
        end
      end
    end

    stub_underscore("MyWeird", "my_weird")

    allow(::Warden::Strategies).to receive(:add).with(an_instance_of(Symbol), an_instance_of(Class))
    symbol = My::Weird::Strategy.register!
    expect(symbol).to be_instance_of(Symbol)
    expect(symbol.to_s).to eq("my_weird")
  end

  it "lets you pick the symbol to register under" do
    module Another # standard:disable Lint/ConstantDefinitionInBlock
      module Weird
        class Strategy
          include WardenOpenidBearer::Registerer
        end
      end
    end

    stub_underscore("AnotherWeird", "another_weird")
    # Must still stub out ::Warden::Strategies.add, as the real thing
    # would whine about there being no `authenticate!` method:
    allow(::Warden::Strategies).to receive(:add)
    symbol = Another::Weird::Strategy.register! :whatever
    expect(symbol).to be_instance_of(Symbol)
    expect(symbol.to_s).to eq("whatever")
  end
end
