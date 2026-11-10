# Changelog

All notable changes to this gem are recorded here.  Versions follow the bare
git tags on `main` (no `v` prefix).

## Unreleased

### Changed

- **Minimum Ruby is now 3.2** (was 3.1).  Ruby 3.1 is end-of-life, and the
  patched `sqlite3` the test suite needs no longer installs on it.
  ActiveRecord/ActiveSupport support is unchanged (>= 6.0, < 9).
- Rails 8.1 is now in the CI matrix, as is Ruby 4.0 (with Rails 7.1+).
- Gem metadata points at `github.com/octoopi/enumbler` and this changelog,
  and the packaged gem ships only `lib/`, the README, the changelog and the
  license.

## 0.11.0

- Added `Enumbler.suppress_database_warnings` (and the
  `ENUMBLER_SUPPRESS_DATABASE_WARNINGS` environment variable) to silence the
  boot-time `[Enumbler Warning]` messages.
- Releases publish through RubyGems trusted publishing from CI.

## 0.10.0

- Support for Rails 7.x and 8.0.
