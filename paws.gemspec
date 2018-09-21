# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'paws/version'

Gem::Specification.new do |spec|
  spec.name          = "paws"
  spec.version       = Paws::VERSION
  spec.authors       = ["Eliot Jordan"]
  spec.email         = ["eliotj@princeton.edu"]

  spec.summary       = 'Gem for working with PUL resources in AWS.'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk", "~> 3"

  spec.add_development_dependency "bixby"
  spec.add_development_dependency "pry-byebug"
end
