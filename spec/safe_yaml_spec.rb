require File.join(File.dirname(__FILE__), "spec_helper")

require "exploitable_back_door"

describe YAML do
  # Essentially stolen from:
  # https://github.com/rails/rails/blob/3-2-stable/activesupport/lib/active_support/core_ext/kernel/reporting.rb#L10-25
  def silence_warnings
    $VERBOSE = nil; yield
  ensure
    $VERBOSE = true
  end

  before :each do
    YAML.disable_symbol_parsing!
  end

  describe "unsafe_load" do
    if SafeYAML::YAML_ENGINE == "psych" && RUBY_VERSION >= "1.9.3"
      it "allows exploits through objects defined in YAML w/ !ruby/hash via custom :[]= methods" do
        backdoor = YAML.unsafe_load("--- !ruby/hash:ExploitableBackDoor\nfoo: bar\n")
        backdoor.should be_exploited_through_setter
      end

      it "allows exploits through objects defined in YAML w/ !ruby/object via the :init_with method" do
        backdoor = YAML.unsafe_load("--- !ruby/object:ExploitableBackDoor\nfoo: bar\n")
        backdoor.should be_exploited_through_init_with
      end
    end

    it "allows exploits through objects w/ sensitive instance variables defined in YAML w/ !ruby/object" do
      backdoor = YAML.unsafe_load("--- !ruby/object:ExploitableBackDoor\nfoo: bar\n")
      backdoor.should be_exploited_through_ivars
    end

    it "allows exploits through sequenced objects" do
      yaml = <<-YAML.unindent
      ---
      - 1
      - 2
      - !ruby/object:ExploitableBackDoor
        foo: bar
      YAML
      array = YAML.unsafe_load(yaml)
      array[2].should be_exploited_through_ivars
    end

    it "allows exploits through nested objects" do
      yaml = <<-YAML.unindent
      ---
      a: 1
      b:
        a: 1
        b: !ruby/object:ExploitableBackDoor
           foo: bar
      YAML
      hash = YAML.unsafe_load(yaml)
      hash['b']['b'].should be_exploited_through_ivars
    end
  end

  describe "safe_load" do
    it "does NOT allow exploits through objects defined in YAML w/ !ruby/hash" do
      expect { YAML.safe_load("--- !ruby/hash:ExploitableBackDoor\nfoo: bar\n") }.to raise_error(SafeYAML::UnsafeTagError)
    end

    it "does NOT allow exploits through objects defined in YAML w/ !ruby/object" do
      expect { YAML.safe_load("--- !ruby/object:ExploitableBackDoor\nfoo: bar\n") }.to raise_error(SafeYAML::UnsafeTagError)
    end

    it "does NOT allow exploits in sequenced objects" do
      yaml = <<-YAML.unindent
      ---
      - 1
      - 2
      - !ruby/object:ExploitableBackDoor
        foo: bar
      YAML
      expect { YAML.safe_load(yaml) }.to raise_error(SafeYAML::UnsafeTagError)
    end

    it "does NOT allow exploits in nested objects" do
      yaml = <<-YAML.unindent
      ---
      a: 1
      b:
        a: 1
        b: !ruby/object:ExploitableBackDoor
           foo: bar
      YAML
      expect { YAML.safe_load(yaml) }.to raise_error(SafeYAML::UnsafeTagError)
    end

    context "for YAML engine #{SafeYAML::YAML_ENGINE}" do
      if SafeYAML::YAML_ENGINE == "psych"
        let(:arguments) {
          if SafeYAML::MULTI_ARGUMENT_YAML_LOAD
            ["foo: bar", nil]
          else
            ["foo: bar"]
          end
        }
        it "uses Psych internally to parse YAML" do
          stub_parser = stub(Psych::Parser)
          Psych::Parser.stub(:new).and_return(stub_parser)
          stub_parser.should_receive(:parse).with(*arguments).twice
          # This won't work now; we just want to ensure Psych::Parser#parse was in fact called.
          YAML.safe_load(*arguments)
        end
      end

      if SafeYAML::YAML_ENGINE == "syck"
        it "uses Syck internally to parse YAML" do
          YAML.should_receive(:parse).with("foo: bar")
          # This won't work now; we just want to ensure YAML::parse was in fact called.
          YAML.safe_load("foo: bar") rescue nil
        end
      end
    end

    it "loads a plain ol' YAML document just fine" do
      YAML.enable_symbol_parsing!
      result = YAML.safe_load <<-YAML.unindent
        foo:
          number: 1
          float: 1.5
          string: Hello, there!
          symbol: :blah
          quoted_symbol_1: ":blah"
          quoted_symbol_2: ':blah'
          y: true
          n: false
          nada:
          date: 2013-02-14
          time: 2013-02-14 09:49:19.419780000 -07:00
          sequence:
            - hi
            - bye
      YAML

      result.should == {
        "foo" => {
          "number"          => 1,
          "float"           => 1.5,
          "string"          => "Hello, there!",
          "symbol"          => :blah,
          "quoted_symbol_1" => ":blah",
          "quoted_symbol_2" => ":blah",
          "y"               => true,
          "n"               => false,
          "nada"            => nil,
          "date"            => YAML.unsafe_load("2013-02-14"),
          "time"            => YAML.unsafe_load("2013-02-14 09:49:19.419780000 -07:00"),
          "sequence"        => ["hi", "bye"]
        }
      }
    end

    it "works for YAML documents with anchors and aliases" do
      result = YAML.safe_load <<-YAML
        - &id001 {}
        - *id001
        - *id001
      YAML

      result.should == [{}, {}, {}]
    end

    if SafeYAML::YAML_ENGINE == "psych"
      # syck doesn't support !binary
      it "works for YAML documents with binary tagged keys" do
        result = YAML.safe_load <<-YAML
          ? !!binary >
            Zm9v
          : "bar"
          ? !!binary >
            YmFy
          : "baz"
        YAML

        result.should == {"foo" => "bar", "bar" => "baz"}
      end

      it "works for YAML documents with binary tagged values" do
        result = YAML.safe_load <<-YAML
          "foo": !!binary >
            YmFy
          "bar": !!binary >
            YmF6
        YAML

        result.should == {"foo" => "bar", "bar" => "baz"}
      end

      it "works for YAML documents with binary tagged array values" do
        result = YAML.safe_load <<-YAML
          - !binary |-
            Zm9v
          - !binary |-
            YmFy
        YAML

        result.should == ["foo", "bar"]
      end
    end

    it "works for YAML documents with sections" do
      result = YAML.safe_load <<-YAML
        mysql: &mysql
          adapter: mysql
          pool: 30
        login: &login
          username: user
          password: password123
        development: &development
          <<: *mysql
          <<: *login
          host: localhost
      YAML

      result.should == {
        "mysql" => {
          "adapter" => "mysql",
          "pool"    => 30
        },
        "login" => {
          "username" => "user",
          "password" => "password123"
        },
        "development" => {
          "adapter"  => "mysql",
          "pool"     => 30,
          "username" => "user",
          "password" => "password123",
          "host"     => "localhost"
        }
      }
    end

    it "correctly prefers explicitly defined values over default values from included sections" do
      # Repeating this test 100 times to increase the likelihood of running into an issue caused by
      # non-deterministic hash key enumeration.
      100.times do
        result = YAML.safe_load <<-YAML
          defaults: &defaults
            foo: foo
            bar: bar
            baz: baz
          custom:
            <<: *defaults
            bar: custom_bar
            baz: custom_baz
        YAML

        result["custom"].should == {
          "foo" => "foo",
          "bar" => "custom_bar",
          "baz" => "custom_baz"
        }
      end
    end

    it "works with multi-level inheritance" do
      result = YAML.safe_load <<-YAML
        defaults: &defaults
          foo: foo
          bar: bar
          baz: baz
        custom: &custom
          <<: *defaults
          bar: custom_bar
          baz: custom_baz
        grandcustom: &grandcustom
          <<: *custom
      YAML

      result.should == {
        "defaults"    => { "foo" => "foo", "bar" => "bar", "baz" => "baz" },
        "custom"      => { "foo" => "foo", "bar" => "custom_bar", "baz" => "custom_baz" },
        "grandcustom" => { "foo" => "foo", "bar" => "custom_bar", "baz" => "custom_baz" }
      }
    end

    context "with custom whitelist defined" do
      class MyClass
        attr_reader :a, :b
        def initialize(a, b)
          @a = a
          @b = b
        end

        def self.new_from_hash(hash)
          self.new(*hash.values_at('a', 'b'))
        end
      end

      before :each do
        if SafeYAML::YAML_ENGINE == "psych"
          YAML.set_whitelist(['!ruby/object:Set',
                              '!map:Hashie::Mash',
                              '!ruby/object:MyClass',])
        else
          YAML.set_whitelist(['tag:ruby.yaml.org,2002:object:Set',
                              'tag:yaml.org,2002:map:Hashie::Mash',
                              'tag:ruby.yaml.org,2002:object:MyClass',])
        end
      end

      after :each do
        YAML.set_whitelist([])
      end

      it "will allow array-structure classes via the whitelist" do
        result = YAML.safe_load <<-YAML.unindent
          --- !ruby/object:Set
          hash:
            1: true
            2: true
            3: true
        YAML

        result.should be_a(Set)
        result.to_a.should =~ [1, 2, 3]
      end

      it "will allow hash-structure classes via the whitelist" do
        result = YAML.safe_load <<-YAML.unindent
          --- !map:Hashie::Mash
          foo: bar
        YAML

        result.should be_a(Hashie::Mash)
        result.to_hash.should == { "foo" => "bar" }

        result = YAML.safe_load <<-YAML.unindent
          --- !ruby/object:MyClass
          a: 1
          b: !ruby/object:MyClass
            a: &70346695583400 !ruby/object:MyClass
              a: 2
              b: *70346695583400
            b: *70346695583400
        YAML

        result.should be_a(MyClass)
        result.a.should == 1
        result.b.should be_a(MyClass)
        result.b.a.should be_a(MyClass)
        result.b.a.a.should == 2
        result.b.a.b.object_id.should == result.b.a.object_id
        result.b.a.object_id.should == result.b.b.object_id
      end
    end
  end

  describe "unsafe_load_file" do
    if SafeYAML::YAML_ENGINE == "psych" && RUBY_VERSION >= "1.9.3"
      it "allows exploits through objects defined in YAML w/ !ruby/hash via custom :[]= methods" do
        backdoor = YAML.unsafe_load_file "spec/exploit.1.9.3.yaml"
        backdoor.should be_exploited_through_setter
      end
    end

    if SafeYAML::YAML_ENGINE == "psych" && RUBY_VERSION >= "1.9.2"
      it "allows exploits through objects defined in YAML w/ !ruby/object via the :init_with method" do
        backdoor = YAML.unsafe_load_file "spec/exploit.1.9.2.yaml"
        backdoor.should be_exploited_through_init_with
      end
    end

    it "allows exploits through objects w/ sensitive instance variables defined in YAML w/ !ruby/object" do
      backdoor = YAML.unsafe_load_file "spec/exploit.1.9.2.yaml"
      backdoor.should be_exploited_through_ivars
    end
  end

  describe "safe_load_file" do
    it "does NOT allow exploits through objects defined in YAML w/ !ruby/hash" do
      expect { YAML.safe_load_file "spec/exploit.1.9.3.yaml" }.to raise_error(SafeYAML::UnsafeTagError)
    end

    it "does NOT allow exploits through objects defined in YAML w/ !ruby/object" do
      expect { YAML.safe_load_file "spec/exploit.1.9.2.yaml" }.to raise_error(SafeYAML::UnsafeTagError)
    end
  end

  describe "load" do
    let(:arguments) {
      if SafeYAML::MULTI_ARGUMENT_YAML_LOAD
        ["foo: bar", nil]
      else
        ["foo: bar"]
      end
    }

    context "with :suppress_warnings set to true" do
      before :each do SafeYAML::OPTIONS[:suppress_warnings] = true; end
      after :each do SafeYAML::OPTIONS[:suppress_warnings] = false; end

      it "doesn't issue a warning if :suppress_warnings option is set to true" do
        SafeYAML::OPTIONS[:suppress_warnings] = true
        Kernel.should_not_receive(:warn)
        YAML.load(*arguments)
      end
    end

    it "issues a warning if the :safe option is omitted" do
      silence_warnings do
        Kernel.should_receive(:warn)
        YAML.load(*arguments)
      end
    end

    it "doesn't issue a warning as long as the :safe option is specified" do
      Kernel.should_not_receive(:warn)
      YAML.load(*(arguments + [{:safe => true}]))
    end

    it "defaults to safe mode if the :safe option is omitted" do
      silence_warnings do
        YAML.should_receive(:safe_load).with(*arguments)
        YAML.load(*arguments)
      end
    end

    it "calls #safe_load if the :safe option is set to true" do
      YAML.should_receive(:safe_load).with(*arguments)
      YAML.load(*(arguments + [{:safe => true}]))
    end

    it "calls #unsafe_load if the :safe option is set to false" do
      YAML.should_receive(:unsafe_load).with(*arguments)
      YAML.load(*(arguments + [{:safe => false}]))
    end

    context "with arbitrary object deserialization enabled by default" do
      before :each do
        YAML.enable_arbitrary_object_deserialization!
      end

      after :each do
        YAML.disable_arbitrary_object_deserialization!
      end

      it "defaults to unsafe mode if the :safe option is omitted" do
        silence_warnings do
          YAML.should_receive(:unsafe_load).with(*arguments)
          YAML.load(*arguments)
        end
      end

      it "calls #safe_load if the :safe option is set to true" do
        YAML.should_receive(:safe_load).with(*arguments)
        YAML.load(*(arguments + [{:safe => true}]))
      end
    end
  end

  describe "load_file" do
    let(:filename) { "spec/ok.yaml" } # doesn't really matter

    it "issues a warning if the :safe option is omitted" do
      silence_warnings do
        Kernel.should_receive(:warn)
        YAML.load_file(filename)
      end
    end

    it "doesn't issue a warning as long as the :safe option is specified" do
      Kernel.should_not_receive(:warn)
      YAML.load_file(filename, :safe => true)
    end

    it "defaults to safe mode if the :safe option is omitted" do
      silence_warnings do
        YAML.should_receive(:safe_load_file).with(filename)
        YAML.load_file(filename)
      end
    end

    it "calls #safe_load_file if the :safe option is set to true" do
      YAML.should_receive(:safe_load_file).with(filename)
      YAML.load_file(filename, :safe => true)
    end

    it "calls #unsafe_load_file if the :safe option is set to false" do
      YAML.should_receive(:unsafe_load_file).with(filename)
      YAML.load_file(filename, :safe => false)
    end

    context "with arbitrary object deserialization enabled by default" do
      before :each do
        YAML.enable_arbitrary_object_deserialization!
      end

      after :each do
        YAML.disable_arbitrary_object_deserialization!
      end

      it "defaults to unsafe mode if the :safe option is omitted" do
        silence_warnings do
          YAML.should_receive(:unsafe_load_file).with(filename)
          YAML.load_file(filename)
        end
      end

      it "calls #safe_load if the :safe option is set to true" do
        YAML.should_receive(:safe_load_file).with(filename)
        YAML.load_file(filename, :safe => true)
      end
    end
  end
end
