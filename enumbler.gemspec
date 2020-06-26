# frozen_string_literal: true

require_relative 'lib/enumbler/version'

Gem::Specification.new do |spec|
  spec.name          = 'enumbler'
  spec.version       = Enumbler::VERSION
  spec.authors       = ['Damon Timm']
  spec.email         = ['damon@linguabee.com']

  spec.summary       = "Enums are terrific, but lack integrity.  Let's add some!"
  spec.description   = 'A more complete description is forthcoming.'
  spec.homepage      = 'https://github.com/linguabee/enumbler'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', ['>= 5.2.3', '< 6.1']
  spec.add_dependency 'activesupport', ['>= 5.2.3', '< 6.1']

  spec.add_development_dependency 'database_cleaner-active_record', '~> 1.8.0'
  spec.add_development_dependency 'fuubar', '~> 2.5'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.9.0'
  spec.add_development_dependency 'rubocop', '~> 0.81.0'
  spec.add_development_dependency 'sqlite3', '~> 1.4.0'
end
