RSpec.describe WardenOpenidBearer::CacheMixin do
  def make_cache_mixin_class(&block)
    klass = Class.new do
      include ::WardenOpenidBearer::CacheMixin
    end
    klass.class_eval(&block) if block
    klass
  end

  it "mixes in" do
    fred = make_cache_mixin_class
    fred_ = fred.new
    expect(fred_).to be_a(fred)
  end

  it "caches" do
    fred = make_cache_mixin_class do
      def arrested_counter
        cached_by("nothing in particular") do
          @counter ||= 0
          @counter += 1
        end
      end
    end
    fred_ = fred.new
    expect(fred_.arrested_counter).to eq(1)
    expect(fred_.arrested_counter).to eq(1)
  end

  it "caches inside the instance" do
    # It seems the `def` and `class` keywords do voodo things to the
    # lexical scope. Because we don't use the latter, we can't have
    # @@class_variables (see the sybilline
    # https://stackoverflow.com/a/10712458 and
    # https://stackoverflow.com/a/48594822). But! By not using the
    # former, we can have a pure, lambda-calculus style class that
    # closes over a local variable (a trick found at
    # https://stackoverflow.com/a/34529095):
    counter = 0
    fred = make_cache_mixin_class do
      define_method :wonky_counter do
        cached_by("nothing in particular") do
          counter += 1
        end
      end
    end
    fred_ = fred.new
    expect(fred_.wonky_counter).to eq(1)
    expect(fred_.wonky_counter).to eq(1)
    fred2_ = fred.new
    expect(fred2_.wonky_counter).to eq(2)
    expect(fred2_.wonky_counter).to eq(2)
  end

  it "caches by objects" do
    fred = make_cache_mixin_class do
      def by_object(obj)
        cached_by(obj) do
          @counter ||= 0
          @counter += 1
        end
      end
    end
    fred_ = fred.new
    thing1 = Object.new
    thing2 = Object.new
    expect(fred_.by_object(thing1)).to eq(1)
    expect(fred_.by_object(thing1)).to eq(1)
    expect(fred_.by_object(thing2)).to eq(2)
    expect(fred_.by_object(thing1)).to eq(1)
    expect(fred_.by_object(thing2)).to eq(2)
    expect(fred_.by_object(thing2)).to eq(2)
  end

  it "invalidates the cache after some time" do
    fred = make_cache_mixin_class do
      attr_accessor :cache_timeout

      def arrested_counter
        cached_by("nothing in particular") do
          @counter ||= 0
          @counter += 1
        end
      end
    end
    fred_ = fred.new
    fred_.cache_timeout = 5

    christmas = Time.utc(2004, 11, 24, 0o1, 0o4, 44)
    allow(::Time).to receive(:now).and_return(christmas)
    expect(fred_.arrested_counter).to eq(1)
    expect(fred_.arrested_counter).to eq(1)

    allow(::Time).to receive(:now).and_return(christmas + 300)
    expect(fred_.arrested_counter).to eq(2)
  end
end
