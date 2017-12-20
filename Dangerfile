# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
declared_trivial = github.pr_title.include? "#trivial"

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

# Warn when there is a big PR
warn("This is a Big PR. Try to break this down if possible.") if git.lines_of_code > 500

# Don't let testing shortcuts get into master by accident
fail("fdescribe left in tests") if `grep -r fdescribe specs/ `.length > 1
fail("fit left in tests") if `grep -r fit specs/ `.length > 1
fail("focus: true left in test") if `grep -r 'focus: true' spec/ `.length > 1


if !git.modified_files.grep(/app\/models\/vacols/).empty?
  warn("This PR changes VACOLS models.  Please ensure this is tested against a UAT VACOLS instance")
end
