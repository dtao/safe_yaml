require "heredoc_unindent"
require "rperft"
require "safe_yaml"
require "rspec/expectations"

SafeYAML::OPTIONS[:default_mode] = :safe
SafeYAML::OPTIONS[:deserialize_symbols] = true

@client = RPerft::Client.new("SafeYAML Performance Tests")

def add_test(description, yaml, repetitions=1000)
  yaml = yaml.unindent
  expected_result = YAML.unsafe_load(yaml)
  safe_result = YAML.safe_load(yaml)

  # safe_result.should == expected_result

  @client.run_test(description, repetitions, :tags => ["unsafe", "ruby-#{RUBY_VERSION}", SafeYAML::YAML_ENGINE]) do
    YAML.unsafe_load(yaml)
  end

  @client.run_test(description, repetitions, :tags => ["safe", "ruby-#{RUBY_VERSION}", SafeYAML::YAML_ENGINE]) do
    YAML.safe_load(yaml)
  end
end

add_test "parsing a huge YAML document", File.read(File.join(File.dirname(__FILE__), "perf_test.yml")), 10

add_test "parsing integers", <<-EOYAML
- 1
- 685230
- +685_230
- 02472256
- 0x_0A_74_AE
- 0b1010_0111_0100_1010_1110
- 190:20:30
- 685,230
EOYAML

# Weird, need to look into this one:
# 685.230_15e+03
add_test "parsing floats", <<-EOYAML
- 3.14
- 6.8523015e+5
- 685_230.15
- 190:20:30.15
- -.inf
- 685,230.15
EOYAML

add_test "parsing booleans", <<-EOYAML
- true
- True
- TRUE
- yes
- Yes
- YES
- on
- On
- ON
- false
- False
- FALSE
- no
- No
- NO
- off
- Off
- OFF
EOYAML

add_test "parsing nils", <<-EOYAML
- 
- ~
- null
- Null
- NULL
EOYAML

add_test "parsing dates and times", <<-EOYAML
- 2013-01-01
- 2001-12-15T02:59:43.1Z
- 2001-12-14t21:59:43.10-05:00
- 2001-12-14 21:59:43.10 -5
- 2001-12-15 2:59:43.10
EOYAML

add_test "parsing strings and symbols", <<-EOYAML
- foo
- bar
- :foo
- :bar
EOYAML

add_test "parsing a document with aliases and anchors", <<-EOYAML
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
staging:
  <<: *development
  host: staging.example.com
EOYAML

@client.submit_results(:append => ENV["APPEND_PERF_TEST_RESULTS"])
