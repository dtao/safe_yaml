require File.join(File.dirname(__FILE__), "spec_helper")

require "safe_yaml"
require "exploitable_back_door"

describe YAML do
  describe "orig_load" do
    if RUBY_VERSION >= "1.9.3"
      it "allows exploits through objects defined in YAML w/ !ruby/hash through custom :[]= methods" do
        backdoor = YAML.orig_load("--- !ruby/hash:ExploitableBackDoor\nfoo: bar\n")
        backdoor.should be_exploited_through_setter
      end
    end

    if RUBY_VERSION >= "1.9.2"
      it "allows exploits through objects defined in YAML w/ !ruby/object through" do
        backdoor = YAML.orig_load("--- !ruby/object:ExploitableBackDoor\nfoo: bar\n")
        backdoor.should be_exploited_through_init_with
      end
    end

    it "allows exploits through objects w/ sensitive instance variables defined in YAML w/ !ruby/object" do
      backdoor = YAML.orig_load("--- !ruby/object:ExploitableBackDoor\nfoo: bar\n")
      backdoor.should be_exploited_through_ivars
    end
  end

  describe "load" do
    it "does NOT allow exploits through objects defined in YAML w/ !ruby/hash" do
      object = YAML.load("--- !ruby/hash:ExploitableBackDoor\nfoo: bar\n")
      object.should_not be_a(ExploitableBackDoor)
    end

    it "does NOT allow exploits through objects defined in YAML w/ !ruby/object" do
      object = YAML.load("--- !ruby/object:ExploitableBackDoor\nfoo: bar\n")
      object.should_not be_a(ExploitableBackDoor)
    end

    it "loads a plain ol' YAML document just fine" do
      result = YAML.load <<-YAML.unindent
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
          "symbol" => :blah,
          "sequence" => ["hi", "bye"]
        }
      }
    end

    it "works for YAML documents with anchors and aliases" do
      result = YAML.load <<-YAML
        - &id001 {}
        - *id001
        - *id001
      YAML

      result.should == [{}, {}, {}]
    end

    it "works for YAML documents with sections" do
      result = YAML.load <<-YAML
        mysql: &foo
          adapter: mysql
          pool: 30
        login: &login
          username: dan
          password: gobbledygook
        local: &local
          <<: *foo
          <<: *login
          host: localhost
      YAML

      result.should == {
        "mysql" => {
          "adapter" => "mysql",
          "pool"    => 30
        },
        "login" => {
          "username" => "dan",
          "password" => "gobbledygook"
        },
        "local" => {
          "adapter"  => "mysql",
          "pool"     => 30,
          "username" => "dan",
          "password" => "gobbledygook",
          "host"     => "localhost"
        }
      }
    end
  end

  describe "orig_load_file" do
    if RUBY_VERSION >= "1.9.3"
      it "allows exploits through objects defined in YAML w/ !ruby/hash through custom :[]= methods" do
        backdoor = YAML.orig_load_file "spec/exploit.1.9.3.yaml"
        backdoor.should be_exploited_through_setter
      end
    end

    if RUBY_VERSION >= "1.9.2"
      it "allows exploits through objects defined in YAML w/ !ruby/object through" do
        backdoor = YAML.orig_load_file "spec/exploit.1.9.2.yaml"
        backdoor.should be_exploited_through_init_with
      end
    end

    it "allows exploits through objects w/ sensitive instance variables defined in YAML w/ !ruby/object" do
      backdoor = YAML.orig_load_file "spec/exploit.1.9.2.yaml"
      backdoor.should be_exploited_through_ivars
    end
  end

  describe "load_file" do
    it "does NOT allow exploits through objects defined in YAML w/ !ruby/hash" do
      object = YAML.load_file "spec/exploit.1.9.3.yaml"
      object.should_not be_a(ExploitableBackDoor)
    end

    it "does NOT allow exploits through objects defined in YAML w/ !ruby/object" do
      object = YAML.load_file "spec/exploit.1.9.2.yaml"
      object.should_not be_a(ExploitableBackDoor)
    end
  end
end
