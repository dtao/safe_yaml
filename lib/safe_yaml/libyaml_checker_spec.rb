describe SafeYAML::LibyamlChecker do
  describe "check_libyaml_version" do
    REAL_YAML_ENGINE = SafeYAML::YAML_ENGINE
    REAL_LIBYAML_VERSION = SafeYAML::LibyamlChecker::LIBYAML_VERSION

    let(:libyaml_patched) { false }

    before :each do
      SafeYAML::LibyamlChecker.stub(:libyaml_patched?).and_return(libyaml_patched)
    end

    after :each do
      silence_warnings do
        SafeYAML::YAML_ENGINE = REAL_YAML_ENGINE
        SafeYAML::LibyamlChecker::LIBYAML_VERSION = REAL_LIBYAML_VERSION
      end
    end

    def test_check_libyaml_version(warning_expected, yaml_engine, libyaml_version=nil)
      silence_warnings do
        SafeYAML.const_set("YAML_ENGINE", yaml_engine)
        SafeYAML::LibyamlChecker.const_set("LIBYAML_VERSION", libyaml_version)
        Kernel.send(warning_expected ? :should_receive : :should_not_receive, :warn)
        SafeYAML::LibyamlChecker.check_libyaml_version
      end
    end

    unless defined?(JRUBY_VERSION)
      it "issues no warnings when 'Syck' is the YAML engine" do
        test_check_libyaml_version(false, "syck")
      end

      it "issues a warning if Psych::LIBYAML_VERSION is not defined" do
        test_check_libyaml_version(true, "psych")
      end

      it "issues a warning if Psych::LIBYAML_VERSION is < 0.1.6" do
        test_check_libyaml_version(true, "psych", "0.1.5")
      end

      it "issues no warning if Psych::LIBYAML_VERSION is == 0.1.6" do
        test_check_libyaml_version(false, "psych", "0.1.6")
      end

      it "issues no warning if Psych::LIBYAML_VERSION is > 0.1.6" do
        test_check_libyaml_version(false, "psych", "1.0.0")
      end

      it "does a proper version comparison (not just a string comparison)" do
        test_check_libyaml_version(false, "psych", "0.1.10")
      end

      context "when the system has a known patched libyaml version" do
        let(:libyaml_patched) { true }

        it "issues no warning, even when Psych::LIBYAML_VERSION < 0.1.6" do
          test_check_libyaml_version(false, "psych", "0.1.4")
        end
      end
    end

    if defined?(JRUBY_VERSION)
      it "issues no warning, as JRuby doesn't use libyaml" do
        test_check_libyaml_version(false, "psych", "0.1.4")
      end
    end
  end
end
