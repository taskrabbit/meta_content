# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'meta_content/version'

Gem::Specification.new do |gem|
  gem.name          = "meta_content"
  gem.version       = MetaContent::VERSION
  gem.authors       = ["Mike Nelson", "Brian Leonard"]
  gem.email         = ["mike@mikeonrails.com", "brian@bleonard.com"]
  gem.description   = %q{Store your data in a key/value table in MySQL}
  gem.summary       = %q{Store your data in a key/value table in MySQL}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
