SafeYAML
========

The **SafeYAML** gem provides an alternative to `YAML.load` suitable for accepting user input in Ruby applications. Unlike `YAML.load`, `YAML.safe_load` will *not* expose apps to arbitrary code execution exploits (such as [the one recently discovered in Rails](http://www.reddit.com/r/netsec/comments/167c11/serious_vulnerability_in_ruby_on_rails_allowing/)).

Installation
------------

Add this line to your application's Gemfile:

    gem "safe_yaml"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install safe_yaml

Usage
-----

Suppose your application were to contain some code like this:

```ruby
class ExploitableClassBuilder
  def []=(key, value)
    @class ||= Class.new

    @class.class_eval <<-EOS
      def #{key}
        #{value}
      end
    EOS
  end

  def create
    @class.new
  end
end
```

Now, if you were to use `YAML.load` on user input anywhere in your application, an attacker could make a request with a carefully-crafted YAML string to execute arbitrary code (yes, including `system("unix command")`) on your servers.

Observe:

    > yaml = <<-EOYAML
    > --- !ruby/hash:ExploitableClassBuilder
    > "foo; end; puts %(I'm in yr system!); def bar": "baz"
    > EOYAML
    => "--- !ruby/hash:ExploitableClassBuilder\n\"foo; end; puts %(I'm in yr system!); def bar\": \"baz\"\n"
    
    > YAML.load(yaml)
    I'm in yr system!
    => #<ExploitableClassBuilder:0x007fdbbe2e25d8 @class=#<Class:0x007fdbbe2e2510>>

With `YAML.safe_load`, that attacker would be thwarted:

    > YAML.safe_load(yaml)
    => {"foo; end; puts %(I'm in yr system!); def bar"=>"baz"}

Requirements
------------

SafeYAML requires Ruby 1.8.7 or newer and works with both [Syck](http://www.ruby-doc.org/stdlib-1.8.7/libdoc/yaml/rdoc/YAML.html) and [Psych](http://github.com/tenderlove/psych).
