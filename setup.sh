#!/bin/bash

echo "🚀 Iniciando configuración ..."

gem build raft_algorithm_ruby.gemspec
gem install ./raft_algorithm_ruby-0.1.0.gem
irb -r raft_algorithm_ruby