# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'event_sourced_record/version'

Gem::Specification.new do |spec|
  spec.name          = "event_sourced_record"
  spec.version       = EventSourcedRecord::VERSION
  spec.authors       = ["Francis Hwang"]
  spec.email         = ["sera@fhwang.net"]
  spec.summary       = %q{Event Sourcing with ActiveRecord.}
  spec.description   = %q{Event Sourcing with ActiveRecord.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.post_install_message = <<-MESSAGE
Thanks for installing!

EventSourcedRecord uses Rails observers. If you are using Rails 4.0 or greater, add `rails-observers` to your Gemfile.
  MESSAGE

  spec.add_dependency 'activemodel'
  spec.add_dependency 'activerecord-immutable', '~> 0.0.3'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'activerecord'
  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'railties'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'pry'
end
