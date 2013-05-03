#!/bin/bash

[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

rvm use 1.8.7@safe_yaml
bundle exec rake perf

rvm use 1.9.2@safe_yaml
YAMLER=syck bundle exec rake perf[true]

rvm use 1.9.3@safe_yaml
YAMLER=syck bundle exec rake perf[true]

rvm use 1.9.2@safe_yaml
YAMLER=psych bundle exec rake perf[true]

rvm use 1.9.3@safe_yaml
YAMLER=psych bundle exec rake perf[true]

rvm use 2.0.0@safe_yaml
YAMLER=psych bundle exec rake perf[true]
