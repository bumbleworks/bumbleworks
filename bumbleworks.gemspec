# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bumbleworks/version'

Gem::Specification.new do |spec|
  spec.name          = "bumbleworks"
  spec.version       = Bumbleworks::VERSION
  spec.authors       = ["Maher Hawash", "Ravi Gadad", "Laurie Kemmerer", "David Miller"]
  spec.email         = ["mhawash@renewfund.com", "ravi@renewfund.com", "laurie@renewfund.com", "dave.miller@renewfund.com"]
  spec.description   = %q{Bumbleworks adds a workflow engine (via ruote[http://github.com/jmettraux/ruote]) to your application.}
  spec.summary       = %q{Framework around ruote[http://github.com/jmettraux/ruote] workflow engine}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "ruote"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'watchr'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'simplecov'
end
