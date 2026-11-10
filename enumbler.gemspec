# frozen_string_literal: true

require_relative "lib/enumbler/version"

Gem::Specification.new do |spec|
  spec.name          = "enumbler"
  spec.version       = Enumbler::VERSION
  spec.authors       = ["Damon Timm"]
  spec.email         = ["damon@linguabee.com"]

  spec.summary       = "Enums are terrific, but lack integrity.  Let's add some!"
  spec.description   = "Database-backed enums for ActiveRecord: real foreign-key lookup tables that behave " \
                       "like enums, with constants, predicates, scopes, and seeding generated from one definition."
  spec.homepage      = "https://github.com/octoopi/enumbler"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.2")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Ship only the library and its docs; the dev tooling (Gemfile variants,
  # CI config, agent notes) stays in the repo.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").grep(%r{\A(lib/|README\.md\z|CHANGELOG\.md\z|LICENSE\.txt\z)})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", [">= 6.0", "< 9"]
  spec.add_dependency "activesupport", [">= 6.0", "< 9"]
  spec.metadata["rubygems_mfa_required"] = "true"
end
