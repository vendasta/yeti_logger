# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yeti_logger/version'

Gem::Specification.new do |spec|
  spec.name          = "yeti_logger"
  spec.version       = YetiLogger::VERSION
  spec.authors       = ["Yesware, Inc"]
  spec.email         = ["engineering@yesware.com"]
  spec.description   = %q{Provides standardized logging}
  spec.summary       = spec.description
  spec.homepage      = ""
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activesupport'

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "redcarpet"
  spec.add_development_dependency "simplecov"
end
