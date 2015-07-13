# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'material_raingular/ace/version'

Gem::Specification.new do |spec|
  spec.name          = "material_raingular-ace"
  spec.version       = MaterialRaingular::Ace::VERSION
  spec.authors       = ["Chris Moody"]
  spec.email         = ["cmoody.eit@gmail.com"]

  spec.summary       = %q{Ace for rails with directive for code window.}
  spec.description   = %q{Extending Material Raingular with an ace code window directive.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib","vendor"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency     "material_raingular"
end
