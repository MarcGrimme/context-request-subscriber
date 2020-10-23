# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'context_request_subscriber/version'

Gem::Specification.new do |s|
  s.name        = 'context_request_subscriber'
  s.version     = ContextRequestSubscriber::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Marc Grimme']
  s.email       = ['marc.grimme at gmail dot com']
  s.license     = 'MIT'
  s.homepage    = 'https://github.com/marcgrimme/context-request-subscriber'
  s.summary     = %(RabbitMQ MessageQueue Subsriber to track requests \
and map to contexts)

  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'bunny'
  s.add_runtime_dependency 'json_api_client'
  s.add_development_dependency 'license_finder', '~> 6.1'
  s.add_development_dependency 'rake', '~> 13'
  s.add_development_dependency 'rspec', '~> 3.8'
  s.add_development_dependency 'rubocop', '~> 1.0'
  s.add_development_dependency 'rubycritic', '~> 4.1'
  s.add_development_dependency 'rubycritic-small-badge', '~> 0.2'
  s.add_development_dependency 'simplecov', '~> 0.17'
  s.add_development_dependency 'simplecov-small-badge', '~> 0.2'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`
                    .split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
