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
    if RUBY_VERSION >= "1.9.3"
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
  end

  describe "unsafe_load_file" do
    if RUBY_VERSION >= "1.9.3"
      it "allows exploits through objects defined in YAML w/ !ruby/hash via custom :[]= methods" do
        backdoor = YAML.unsafe_load_file "spec/exploit.1.9.3.yaml"
        backdoor.should be_exploited_through_setter
      end

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
      if RUBY_VERSION >= "1.9.3"
        ["foo: bar", nil]
      else
        ["foo: bar"]
      end
    }

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
    it "issues a warning if the :safe option is omitted" do
      silence_warnings do
        Kernel.should_receive(:warn)
        YAML.load_file("spec/exploit.1.9.2.yaml")
      end
    end

    it "doesn't issue a warning as long as the :safe option is specified" do
      Kernel.should_not_receive(:warn)
      YAML.load_file("spec/exploit.1.9.2.yaml", :safe => true)
    end


    it "defaults to safe mode if the :safe option is omitted" do
      silence_warnings do
        YAML.should_receive(:safe_load_file).with("spec/exploit.1.9.2.yaml")
        YAML.load_file("spec/exploit.1.9.2.yaml")
      end
    end

    it "calls #safe_load_file if the :safe option is set to true" do
      YAML.should_receive(:safe_load_file).with("spec/exploit.1.9.2.yaml")
      YAML.load_file("spec/exploit.1.9.2.yaml", :safe => true)
    end

    it "calls #unsafe_load_file if the :safe option is set to false" do
      YAML.should_receive(:unsafe_load_file).with("spec/exploit.1.9.2.yaml")
      YAML.load_file("spec/exploit.1.9.2.yaml", :safe => false)
    end
  end
end
