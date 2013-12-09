#!/bin/bash

[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

rvm use 1.8.7
bundle exec rake spec

rvm use 1.9.2
YAMLER=syck bundle exec rake spec

rvm use 1.9.3
YAMLER=syck bundle exec rake spec

rvm use 1.9.2
YAMLER=psych bundle exec rake spec

rvm use 1.9.3
YAMLER=psych bundle exec rake spec

rvm use 2.0.0
YAMLER=psych bundle exec rake spec

rvm use jruby
JRUBY_OPTS=--1.8 bundle exec rake spec

rvm use jruby
JRUBY_OPTS=--1.9 bundle exec rake spec
