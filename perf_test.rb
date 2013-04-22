# Generate a huge YAML document.
require "randy"
require "yaml"

def populate_hash(hash, repetitions)
  repetitions.times do
    hash["number_#{Randy.string(5)}"] = Randy.integer(1..100)
    hash["string_#{Randy.string(5)}"] = Randy.string(32)
    hash["array_#{Randy.string(5)}"] = (1..Randy.integer(2..10)).map { generate_something }
    hash["hash_#{Randy.string(5)}"] = generate_hash(repetitions / 2)
  end
end

def generate_something
  case Randy.integer(1..100)
  when 1..25
    Randy.string(32)
  when 26..50
    Randy.integer(1..100)
  when 51..75
    Randy.decimal(1..100)
  when 76..100
    Randy.string(256)
  end
end

def generate_hash(repetitions=10)
  hash = {}
  populate_hash(hash, repetitions)
  hash
end

File.open(File.expand_path("spec/perf_test.yml"), "w") do |f|
  f.write(generate_hash.to_yaml)
end
