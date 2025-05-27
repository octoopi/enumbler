#!/usr/bin/env ruby

# frozen_string_literal: true

# Put this file into your path and use `<file> install` to add a new hook
# or use it as a binary to check changed files

require "shellwords"

if ARGV == ["install"]
  exec "ln", "-sf", File.expand_path(File.basename(__FILE__), __dir__), ".git/hooks/pre-commit"
else
  raise unless ARGV == []
end

changed = `git status --porcelain`
  .split("\n")
  .map { |l| l.split(" ", 2) }
  .select { |status, _| %w[A AM M].include?(status) }
  .map { |_, file| file.delete('"') }

exit if changed.empty?

parallel = (if begin
  File.read(".rubocop.yml").include?("UseCache: false")
rescue StandardError
  false
end
              ""
            else
              " --parallel"
            end)

# grab the Process::Status from $?
status = $?

unless status.success?
  puts result
  exit status.exitstatus
end

# if we got here, rubocop passed
exit 0
