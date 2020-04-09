#!/usr/bin/env ruby
# Put this file into your path and use `<file> install` to add a new hook
# or use it as a binary to check changed files

require 'shellwords'

if ARGV == ["install"]
  exec "ln", "-sf", File.expand_path(File.basename(__FILE__), __dir__), ".git/hooks/pre-commit"
else
  raise unless ARGV == []
end

changed = `git status --porcelain`.
  split("\n").
  map { |l| l.split(" ", 2) }.
  select { |status, _| ["A", "AM", "M"].include?(status) }.
  map { |_, file| file.delete('"') }

exit if changed.empty?

parallel = ((File.read(".rubocop.yml").include?("UseCache: false") rescue false) ? "" : " --parallel")
result = `bundle exec rubocop #{parallel} --color --force-exclusion #{changed.shelljoin}`
puts result unless $?.success?
exit $?.exitstatus
