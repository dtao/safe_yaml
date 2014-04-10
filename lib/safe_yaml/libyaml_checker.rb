require "set"

module SafeYAML
  class LibyamlChecker
    LIBYAML_VERSION = YAML_ENGINE == "psych" && Psych.const_defined?("LIBYAML_VERSION", false) ? Psych::LIBYAML_VERSION : nil

    # Do proper version comparison (e.g. so 0.1.10 is >= 0.1.6)
    SAFE_LIBYAML_VERSION = Gem::Version.new("0.1.6")

    KNOWN_PATCHED_LIBYAML_VERSIONS = Set.new([
      # http://people.canonical.com/~ubuntu-security/cve/2014/CVE-2014-2525.html
      "0.1.4-2ubuntu0.12.04.3",
      "0.1.4-2ubuntu0.12.10.3",
      "0.1.4-2ubuntu0.13.10.3",
      "0.1.4-3ubuntu3",

      # https://security-tracker.debian.org/tracker/CVE-2014-2525
      "0.1.3-1+deb6u4",
      "0.1.4-2+deb7u4",
      "0.1.4-3.2"
    ]).freeze

    def self.check_libyaml_version
      old_libyaml_version = YAML_ENGINE == "psych" && Gem::Version.new(LIBYAML_VERSION || "0") < SAFE_LIBYAML_VERSION

      if old_libyaml_version && !defined?(JRUBY_VERSION) && !libyaml_patched?
        Kernel.warn <<-EOWARNING.gsub(/^ +/, '  ')

          \e[33mSafeYAML Warning\e[39m
          \e[33m----------------\e[39m

          \e[31mYou may have an outdated version of libyaml (#{LIBYAML_VERSION}) installed on your system.\e[39m

          Prior to 0.1.6, libyaml is vulnerable to a heap overflow exploit from malicious YAML payloads.

          For more info, see:
          https://www.ruby-lang.org/en/news/2014/03/29/heap-overflow-in-yaml-uri-escape-parsing-cve-2014-2525/

          The easiest thing to do right now is probably to update Psych to the latest version and enable
          the 'bundled-libyaml' option, which will install a vendored libyaml with the vulnerability patched:

          \e[32mgem install psych -- --enable-bundled-libyaml\e[39m

        EOWARNING
      end
    end

    def self.libyaml_patched?
      return false if (`which dpkg` rescue '').empty?
      libyaml_version = `dpkg -s libyaml-0-2`.match(/^Version: (.*)$/)
      return false if libyaml_version.nil?
      KNOWN_PATCHED_LIBYAML_VERSIONS.include?(libyaml_version[1])
    end
  end
end
