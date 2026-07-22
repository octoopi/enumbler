# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Enumbler is a Ruby gem that provides database-backed enums for ActiveRecord: real foreign-key lookup tables that behave like `enum`s. It supports ActiveRecord/ActiveSupport >= 6.0, < 9 and Ruby >= 3.1.

## Commands

```bash
bin/setup                                  # install dependencies
bundle exec rspec                          # run all tests
bundle exec rspec spec/enumbler_spec.rb:42 # run a single test by file:line
bundle exec rubocop                        # lint (also runs as a lefthook pre-commit hook)
```

### Matrix testing

CI tests Ruby 3.1–3.4 against Rails 6.0–8.0 using the `Gemfile.rails*` files. To reproduce locally:

```bash
BUNDLE_GEMFILE=Gemfile.rails7.2 bundle install
BUNDLE_GEMFILE=Gemfile.rails7.2 bundle exec rspec
```

When changing dependencies, keep all `Gemfile.rails*` variants (and their lockfiles) in sync with the main `Gemfile`.

### Branching & releasing

Modified git flow (see README "Development"): feature branches off `develop`; releases go to `main` via `release/x.y.z` (or `hotfix/x.y.z` off `main`), then the tag is merged back into `develop`. A release is a bare version tag on `main` (no `v` prefix, e.g. `0.10.0`) matching `lib/enumbler/version.rb`; pushing the tag makes CI run the rspec matrix and publish the gem to rubygems.org.

## Architecture

The gem is four small files under `lib/enumbler/`, split across the two sides of the relationship:

- **`lib/enumbler.rb`** (`Enumbler` module) — included in `ApplicationRecord`; gives *consuming* models `enumbled_to :color`, a `belongs_to` replacement. It defines class scopes (`House.color(:black)`), per-enum predicates (`house.black?`, `house.not_black?`, optionally prefixed), and db-free helper attributes (`house.color_label`, `color_enum`, `color_graphql_enum`).

- **`lib/enumbler/enabler.rb`** (`Enumbler::Enabler`) — included in the *lookup* model (e.g. `Color`); provides the `enumble :black, 1, ...` DSL. Each call builds an `Enumble`, registers it in the class-level `@enumbles` collection, and metaprograms constants (`Color::BLACK`), class finders (`Color.black`, `Color.black(:label)`), and predicates — with conflict detection against ActiveRecord methods (modeled on `ActiveRecord::Enum`). Also holds all the `find_enumble(s)` / `ids_from_enumbler` lookup methods (in-memory, no db hit; bang variants raise `Enumbler::Error`) and `seed_the_enumbler(!)` for syncing the definitions into the database table.

- **`lib/enumbler/enumble.rb`** (`Enumbler::Enumble`) — plain value object for one enum row (id, enum symbol, label, extra attributes). Equality is loose: two Enumbles are `==` if id **or** enum **or** label match (this is how duplicate definitions are caught).

- **`lib/enumbler/collection.rb`** — an `Array` subclass with `method_missing` so `Color.enumbles.black` works.

- **`lib/enumbler/core_ext/symbol/case_equality_operator.rb`** — patches `Symbol#===` so `case Color.black; when :black` works. It's a global core extension; be careful changing it.

The label column defaults to `label` but can be remapped per-model with `enumbler_label_column_name :emotion`; internally `Enumble#label` always refers to the enumbler value regardless of the underlying column.

## Tests

Specs run against an in-memory SQLite database (`spec/support/establish_sqlite_connection.rb`); each spec file defines its own schema with `ActiveRecord::Schema.define` and DatabaseCleaner wraps each example in a transaction. `spec/enumbler_spec.rb` covers nearly everything and defines the shared test models (Color, House, Feeling). Rails-version-conditional behavior may need `BUNDLE_GEMFILE` runs to verify.

## Style

RuboCop enforces double-quoted strings, max line length 119, trailing commas in multiline literals, and `TargetRubyVersion: 3.4` — but code must still run on Ruby 3.1 (see the gemspec), so avoid 3.2+-only syntax.
