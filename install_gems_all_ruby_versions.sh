#!/bin/bash

[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

rvm use 1.8.7@safe_yaml
bundle install

rvm use 1.9.2@safe_yaml
YAMLER=syck bundle install

rvm use 1.9.3@safe_yaml
YAMLER=syck bundle install

rvm use 2.0.0@safe_yaml
YAMLER=psych bundle install
