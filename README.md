SafeYAML
========

[![Build Status](https://travis-ci.org/dtao/safe_yaml.png)](http://travis-ci.org/dtao/safe_yaml)

The **SafeYAML** gem provides an alternative implementation of `YAML.load` suitable for accepting user input in Ruby applications. Unlike Ruby's built-in implementation of `YAML.load`, SafeYAML's version will not expose apps to arbitrary code execution exploits (such as [the ones recently](http://www.reddit.com/r/netsec/comments/167c11/serious_vulnerability_in_ruby_on_rails_allowing/) [discovered in Rails](http://www.h-online.com/open/news/item/Rails-developers-close-another-extremely-critical-flaw-1793511.html)).

Installation
------------

Add this line to your application's Gemfile:

    gem "safe_yaml"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install safe_yaml

Purpose
-------

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

Now, if you were to use `YAML.load` on user input anywhere in your application without the SafeYAML gem installed, an attacker could make a request with a carefully-crafted YAML string to execute arbitrary code (yes, including `system("unix command")`) on your servers.

Observe:

```ruby
yaml = <<-EOYAML
--- !ruby/hash:ExploitableClassBuilder
"foo; end; puts %(I'm in yr system!); def bar": "baz"
EOYAML
```

    > YAML.load(yaml)
    I'm in yr system!
    => #<ExploitableClassBuilder:0x007fdbbe2e25d8 @class=#<Class:0x007fdbbe2e2510>>

With SafeYAML, that attacker would be thwarted:

    > require "safe_yaml"
    => true
    > YAML.safe_load(yaml)
    => {"foo; end; puts %(I'm in yr system!); def bar"=>"baz"}

Usage
-----

`YAML.safe_load` will load YAML without allowing arbitrary object deserialization.

`YAML.unsafe_load` will exhibit Ruby's built-in behavior: to allow the deserialization of arbitrary objects.

By default, when you require the safe_yaml gem in your project, `YAML.load` is patched to internally call `safe_load`. The patched method also accepts a `:safe` flag to specify which version to use:

```ruby
# Ruby >= 1.9.3
YAML.load(yaml, filename, :safe => true) # calls safe_load
YAML.load(yaml, filename, :safe => false) # calls unsafe_load

# Ruby < 1.9.3
YAML.load(yaml, :safe => true) # calls safe_load
YAML.load(yaml, :safe => false) # calls unsafe_load
```

The default behavior can be switched to unsafe loading by calling `SafeYAML::OPTIONS[:default_mode] = :unsafe`. In this case, the `:safe` flag still has the same effect, but the defaults are reversed (so calling `YAML.load` will have the same behavior as if the safe_yaml gem weren't required).

This gem will also warn you whenever you use `YAML.load` without specifying the `:safe` option, or if you have not explicitly specified a default mode using the `:default_mode` option.

Supported Types
---------------

The way that SafeYAML works is by restricting the kinds of objects that can be deserialized via `YAML.load`. More specifically, only the following types of objects can be deserialized by default:

- Hashes
- Arrays
- Strings
- Numbers
- Dates
- Times
- Booleans
- Nils

Deserialization of symbols can also be enabled by setting `SafeYAML::OPTIONS[:deserialize_symbols] = true` (for example, in an initializer). Be aware, however, that symbols in Ruby are not garbage-collected; therefore enabling symbol deserialization in your application may leave you vulnerable to [DOS attacks](http://en.wikipedia.org/wiki/Denial-of-service_attack).

Whitelisting Trusted Types
--------------------------

SafeYAML now also supports **whitelisting** certain YAML tags for trusted types. This is handy when your application may use YAML to serialize and deserialize certain types not listed above, which you know to be free of any deserialization-related vulnerabilities. You can whitelist tags via the `:whitelisted_tags` option:

```ruby
# Using Syck (unfortunately, Syck and Psych use different tagging schemes)
SafeYAML::OPTIONS[:whitelisted_tags] = ["tag:ruby.yaml.org,2002:object:OpenStruct"]

# Using Psych
SafeYAML::OPTIONS[:whitelisted_tags] = ["!ruby/object:OpenStruct"]
```

When SafeYAML encounters whitelisted tags in a YAML document, it will default to the deserialization capabilities of the underlying YAML engine (i.e., either Syck or Psych).

**However**, this feature will *not* allow would-be attackers to embed untrusted types within trusted types:

```ruby
yaml = <<-EOYAML
--- !ruby/object:OpenStruct 
table: 
  :backdoor: !ruby/hash:ExploitableClassBuilder 
    "foo; end; puts %(I'm in yr system!); def bar": "baz"
EOYAML
```

    > YAML.safe_load(yaml)
    => #<OpenStruct :backdoor={"foo; end; puts %(I'm in yr system!); def bar"=>"baz"}>

You may prefer, rather than quietly sanitizing and accepting YAML documents with unknown tags, to fail loudly when questionable data is encountered. In this case, you can also set the `:raise_on_unknown_tag` option to `true`:

```ruby
SafeYAML::OPTIONS[:raise_on_unknown_tag] = true
```

    > YAML.safe_load(yaml)
    => RuntimeError: Unknown YAML tag '!ruby/hash:ExploitableClassBuilder'

Pretty sweet, right?

Known Issues
------------

Be aware that some Ruby libraries, particularly those requiring inter-process communication, leverage YAML's object deserialization functionality and therefore may break or otherwise be impacted by SafeYAML. The following list includes known instances of SafeYAML's interaction with other Ruby gems:

- [**Guard**](https://github.com/guard/guard): Uses YAML as a serialization format for notifications. The data serialized uses symbolic keys, so setting `SafeYAML::OPTIONS[:deserialize_symbols] = true` is necessary to allow Guard to work.
- [**sidekiq**](https://github.com/mperham/sidekiq): Uses a YAML configiuration file with symbolic keys, so setting `SafeYAML::OPTIONS[:deserialize_symbols] = true` should allow it to work.

The above list will grow over time, as more issues are discovered.

Caveat
------

This gem is quite young, and so the API may (read: *will*) change in future versions. The goal of the gem is to make it as easy as possible to protect existing applications from object deserialization exploits. Any and all feedback is more than welcome.

Requirements
------------

SafeYAML requires Ruby 1.8.7 or newer and works with both [Syck](http://www.ruby-doc.org/stdlib-1.8.7/libdoc/yaml/rdoc/YAML.html) and [Psych](http://github.com/tenderlove/psych).

If you are using a version of Ruby where Psych is the default YAML engine (e.g., 1.9.3) but you want to use Syck, be sure to set `YAML::ENGINE.yamler = "syck"` **before** requiring the safe_yaml gem.
