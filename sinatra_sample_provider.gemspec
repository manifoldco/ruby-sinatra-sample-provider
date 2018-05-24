# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "sinatra_sample_provider"
  spec.version       = "0.0.1"
  spec.authors       = ["James Bowes"]
  spec.email         = ["jbowes@repl.ca"]

  spec.summary       = "Sample Manifold provider app using Sinatra"
  spec.homepage      = "https://github.com/manifoldco/ruby-sinatra-sample-provider"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'sinatra', '~> 1.4.8'
  spec.add_dependency 'sinatra-contrib', '~> 1.4.7'
  spec.add_dependency 'oauth2', '~> 1.3.1'
  spec.add_dependency 'manifoldco_signature', '~> 0.1.4'
end
