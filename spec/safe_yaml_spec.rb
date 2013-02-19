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
    SafeYAML::OPTIONS[:deserialize_symbols] = false
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

    context "with special whitelisted tags defined" do
      before :each do
        if SafeYAML::YAML_ENGINE == "psych"
          SafeYAML::OPTIONS[:whitelisted_tags] = ["!ruby/object:OpenStruct"]
        else
          SafeYAML::OPTIONS[:whitelisted_tags] = ["tag:ruby.yaml.org,2002:object:OpenStruct"]
        end
      end

      after :each do
        SafeYAML.restore_defaults!
      end

      it "effectively ignores the whitelist (since everything is whitelisted)" do
        result = YAML.unsafe_load <<-YAML.unindent
          --- !ruby/object:OpenStruct 
          table: 
            :backdoor: !ruby/object:ExploitableBackDoor 
              foo: bar
        YAML

        result.should be_a(OpenStruct)
        result.backdoor.should be_exploited_through_ivars
      end
    end
  end

  describe "safe_load" do
    it "does NOT allow exploits through objects defined in YAML w/ !ruby/hash" do
      object = YAML.safe_load("--- !ruby/hash:ExploitableBackDoor\nfoo: bar\n")
      object.should_not be_a(ExploitableBackDoor)
    end

    it "does NOT allow exploits through objects defined in YAML w/ !ruby/object" do
      object = YAML.safe_load("--- !ruby/object:ExploitableBackDoor\nfoo: bar\n")
      object.should_not be_a(ExploitableBackDoor)
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
          Psych.should_receive(:parse).with(*arguments)
          # This won't work now; we just want to ensure Psych::Parser#parse was in fact called.
          YAML.safe_load(*arguments) rescue nil
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
      result = YAML.safe_load <<-YAML.unindent
        foo:
          number: 1
          string: Hello, there!
          symbol: :blah
          sequence:
            - hi
            - bye
      YAML

      result.should == {
        "foo" => {
          "number" => 1,
          "string" => "Hello, there!",
          "symbol" => ":blah",
          "sequence" => ["hi", "bye"]
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
    
    it "returns false when parsing an empty document" do
      result = YAML.safe_load ""
      result.should == false
    end

    context "with custom initializers defined" do
      before :each do
        if SafeYAML::YAML_ENGINE == "psych"
          SafeYAML::OPTIONS[:custom_initializers] = {
            "!set" => lambda { Set.new },
            "!hashiemash" => lambda { Hashie::Mash.new }
          }
        else
          SafeYAML::OPTIONS[:custom_initializers] = {
            "tag:yaml.org,2002:set" => lambda { Set.new },
            "tag:yaml.org,2002:hashiemash" => lambda { Hashie::Mash.new }
          }
        end
      end

      after :each do
        SafeYAML.restore_defaults!
      end

      it "will use a custom initializer to instantiate an array-like class upon deserialization" do
        result = YAML.safe_load <<-YAML.unindent
          --- !set
          - 1
          - 2
          - 3
        YAML

        result.should be_a(Set)
        result.to_a.should =~ [1, 2, 3]
      end

      it "will use a custom initializer to instantiate a hash-like class upon deserialization" do
        result = YAML.safe_load <<-YAML.unindent
          --- !hashiemash
          foo: bar
        YAML

        result.should be_a(Hashie::Mash)
        result.to_hash.should == { "foo" => "bar" }
      end
    end

    context "with special whitelisted tags defined" do
      before :each do
        if SafeYAML::YAML_ENGINE == "psych"
          SafeYAML::OPTIONS[:whitelisted_tags] = ["!ruby/object:OpenStruct"]
        else
          SafeYAML::OPTIONS[:whitelisted_tags] = ["tag:ruby.yaml.org,2002:object:OpenStruct"]
        end

        # Necessary for deserializing OpenStructs properly.
        SafeYAML::OPTIONS[:deserialize_symbols] = true
      end

      after :each do
        SafeYAML.restore_defaults!
      end

      it "will allow objects to be deserialized for whitelisted tags" do
        result = YAML.safe_load("--- !ruby/object:OpenStruct\ntable:\n  foo: bar\n")
        result.should be_a(OpenStruct)
        result.instance_variable_get(:@table).should == { "foo" => "bar" }
      end

      it "will not deserialize objects without whitelisted tags" do
        result = YAML.safe_load("--- !ruby/hash:ExploitableBackDoor\nfoo: bar\n")
        result.should_not be_a(ExploitableBackDoor)
        result.should == { "foo" => "bar" }
      end

      it "will not allow non-whitelisted objects to be embedded within objects with whitelisted tags" do
        result = YAML.safe_load <<-YAML.unindent
          --- !ruby/object:OpenStruct 
          table: 
            :backdoor: !ruby/object:ExploitableBackDoor 
              foo: bar
        YAML

        result.should be_a(OpenStruct)
        result.backdoor.should_not be_a(ExploitableBackDoor)
        result.backdoor.should == { "foo" => "bar" }
      end

      context "with the :raise_on_unknown_tag option enabled" do
        before :each do
          SafeYAML::OPTIONS[:raise_on_unknown_tag] = true
        end

        after :each do
          SafeYAML.restore_defaults!
        end

        it "raises an exception if a non-nil, non-whitelisted tag is encountered" do
          lambda {
            YAML.safe_load <<-YAML.unindent
              --- !ruby/object:Unknown
              foo: bar
            YAML
          }.should raise_error
        end

        it "checks all tags, even those within objects with trusted tags" do
          lambda {
            YAML.safe_load <<-YAML.unindent
              --- !ruby/object:OpenStruct
              table:
                :backdoor: !ruby/object:Unknown
                  foo: bar
            YAML
          }.should raise_error
        end

        it "does not raise an exception as long as all tags are whitelisted" do
          result = YAML.safe_load <<-YAML.unindent
            --- !ruby/object:OpenStruct
            table:
              :backdoor:
                foo: bar
          YAML

          result.should be_a(OpenStruct)
          result.backdoor.should == { "foo" => "bar" }
        end
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
      object = YAML.safe_load_file "spec/exploit.1.9.3.yaml"
      object.should_not be_a(ExploitableBackDoor)
    end

    it "does NOT allow exploits through objects defined in YAML w/ !ruby/object" do
      object = YAML.safe_load_file "spec/exploit.1.9.2.yaml"
      object.should_not be_a(ExploitableBackDoor)
    end
  end

  describe "load" do
    let (:arguments) {
      if SafeYAML::MULTI_ARGUMENT_YAML_LOAD
        ["foo: bar", nil]
      else
        ["foo: bar"]
      end
    }

    context "as long as a :default_mode has been specified" do
      after :each do
        SafeYAML.restore_defaults!
      end

      it "doesn't issue a warning for safe mode, since an explicit mode has been set" do
        SafeYAML::OPTIONS[:default_mode] = :safe
        Kernel.should_not_receive(:warn)
        YAML.load(*arguments)
      end

      it "doesn't issue a warning for unsafe mode, since an explicit mode has been set" do
        SafeYAML::OPTIONS[:default_mode] = :unsafe
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
        SafeYAML::OPTIONS[:default_mode] = :unsafe
      end

      after :each do
        SafeYAML.restore_defaults!
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
    let(:filename) { "spec/exploit.1.9.2.yaml" } # doesn't really matter

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
        SafeYAML::OPTIONS[:default_mode] = :unsafe
      end

      after :each do
        SafeYAML.restore_defaults!
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
