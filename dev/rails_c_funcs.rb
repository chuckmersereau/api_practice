# All of the methods in the dev folder are intended to be run from "rails c"
# to help debugging and fixing user issues.

# By default all *_util.rb files in the util folder are loaded
Dir['./dev/util/*_util.rb'].each { |file| load file }

# Other files such as those in dev/migrate or dev/fixers can be loaded manually

# The migrate folder is for processes that are run to transform the data in some
# way that would be more complicated than a typical Rails migration e.g. to run
# a process to set some type of computed default values for a column before
# deploying code that will display that column.

# The fixers folder is intended for more specialized or complex fixes for
# specific users. They may end up being useful for fixing other user accounts
# but because of their specific nature to that user they might not be applicable
# to as wide a range of cases to warrant moving to the util folder to be
# auto-loaded.
