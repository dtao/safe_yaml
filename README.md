SafeYAML
========

*Parse YAML safely, without that pesky arbitrary code execution vulnerability.*

***

The **safe_yaml** gem offers an alternative to `YAML.load` suitable for accepting user input. Unlike `YAML.load`, `YAML.safe_load` will *not* expose your Ruby app to arbitrary code execution exploits (such as [the one recently discovered in Rails](http://www.reddit.com/r/netsec/comments/167c11/serious_vulnerability_in_ruby_on_rails_allowing/)).

Observe!

```ruby
class ExploitableMap
  def []=(key, value)
    self.class.class_eval <<-EOS
      def #{key}
        return "#{value}"
      end
    EOS
  end
end
```

If your application were to contain code like this and use `YAML.load` anywhere on user input, an attacker could craft a YAML string to execute any code (yes, including `system("unix command")`) on your servers:

    > yaml = <<-EOYAML
    > --- !ruby/hash:ExploitableMap
    > "foo; end; puts %(I'm in yr system!); def bar": "baz"
    > EOYAML
    => "--- !ruby/hash:ExploitableMap\n\"foo; end; puts %(I'm in yr system!); def bar\": \"baz\"\n"
    
    > YAML.load(yaml)
    I'm in yr system!
    => #<ExploitableMap:0x007ffadca0ca10> 

With `YAML.safe_load`, that attacker would be thwarted:

    > YAML.safe_load(yaml)
    => {"foo; end; puts %(I'm in yr system!); def bar"=>"baz"} 

SafeYAML requires Ruby 1.8.7 or newer and works with both [Syck](http://www.ruby-doc.org/stdlib-1.8.7/libdoc/yaml/rdoc/YAML.html) and [Psych](http://github.com/tenderlove/psych).
