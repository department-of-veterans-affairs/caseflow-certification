# rubocop:disable Metrics/LineLength
source ENV["GEM_SERVER_URL"] || "https://rubygems.org"

gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "8dde00d67b7c629e4b871f8dcb3617bfe989b3db"

gem "moment_timezone-rails"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "5.1.6"
# Use sqlite3 as the database for Active Record
gem "activerecord-jdbcsqlite3-adapter", platforms: :jruby
gem "sqlite3", platforms: [:ruby, :mswin, :mingw, :mswin, :x64_mingw]
# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"

# Use jquery as the JavaScript library
gem "jquery-rails"

# React
gem "react_on_rails", "8.0.6"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.0"
# bundle exec rake doc:rails generates the API under doc/api.
gem "sdoc", "~> 0.4.0", group: :doc

gem "active_model_serializers", "~> 0.10.0"

# soft delete gem
gem "paranoia", "~> 2.2"

gem "dogstatsd-ruby"

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Application server: Puma
# Puma was chosen because it handles load of 40+ concurrent users better than Unicorn and Passenger
# Discussion: https://github.com/18F/college-choice/issues/597#issuecomment-139034834
gem "puma", "~> 2.16.0"

# use to_b method to convert string to boolean
gem "wannabe_bool"

# Style
gem "uswds-rails", git: "https://github.com/18F/uswds-rails-gem.git"

# BGS
gem "bgs", git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", ref: "bc9c89591ac5830939476bd6eb96c1a2b415fdcb"

# PDF Tools
gem "pdf-forms"
#
gem "pdfjs_viewer-rails", git: "https://github.com/senny/pdfjs_viewer-rails.git", ref: "a4249eacbf70175db63b57e9f364d0a9a79e2b43"

# Error reporting to Sentry
gem "sentry-raven"

gem "newrelic_rpm"

# Used to colorize output for rake tasks
gem "rainbow"

# Used to speed up reporting
gem "parallel"

# execjs runtime
gem "therubyracer", platforms: :ruby

gem "pg", platforms: :ruby

gem "connect_vbms", git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", ref: "b4d61f190ac8f6f397db245a257a89238970a224"

gem "redis-rails", "~> 5.0.2"

gem "prometheus-client", "~> 0.7.1"

gem "request_store"

# State machine
gem "aasm", "4.11.0"

gem "font-awesome-sass"

gem "redis-namespace"

# catch problematic migrations at development/test time
gem "zero_downtime_migrations"

# nokogiri versions before 1.8.3 are affected by CVE-2018-8048. Explicitly define nokogiri version here to avoid that.
# https://github.com/sparklemotion/nokogiri/pull/1746
gem "nokogiri", ">= 1.8.3"

group :production, :staging, :ssh_forwarding, :development, :test do
  # Oracle DB
  gem "activerecord-oracle_enhanced-adapter"
  gem "ruby-oci8"
end

# Development was ommited due to double logging issue (https://github.com/heroku/rails_stdout_logging/issues/1)
group :production, :staging do
  gem "rails_stdout_logging"
end

group :stubbed, :test, :development, :demo do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: :ruby
  gem "pry"
  gem "pry-byebug"
  gem "rb-readline"

  # Linters
  gem "jshint", platforms: :ruby
  gem "rubocop", "~> 0.52.1", require: false
  gem "scss_lint", require: false

  # Security scanners
  gem "brakeman"
  gem "bundler-audit"

  # Testing tools
  gem "faker"
  gem "rspec"
  gem "rspec-rails"
  # gem 'guard-rspec', '4.7.1' # removed because downstream dep requires ruby 2.5
  gem "capybara"
  gem "capybara-screenshot"
  gem "simplecov", git: "https://github.com/colszowka/simplecov.git", require: false
  gem "sniffybara", git: "https://github.com/department-of-veterans-affairs/sniffybara.git", branch: "master"
  gem "timecop"

  gem "database_cleaner"

  # to save and open specific page in capybara tests
  gem "launchy"

  gem "activerecord-import"

  gem "danger", "5.5.5"

  # For CircleCI test metadata analysis
  gem "rspec_junit_formatter"

  # Added at 2018-05-16 22:09:10 -0400 by mdbenjam:
  gem "factory_bot_rails", "~> 4.8"
end

group :stubbed, :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "dotenv-rails"
  gem "foreman"
  gem "web-console", "~> 3.0", platforms: :ruby

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring', platforms: :ruby

  # Include the IANA Time Zone Database on Windows, where Windows doesn't ship with a timezone database.
  # POSIX systems should have this already, so we're not going to bring it in on other platforms
  gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
end

gem "shoryuken", "3.1.11"

gem "paper_trail", "8.1.2"
# rubocop:enable Metrics/LineLength

gem "holidays", "~> 6.4"

gem "roo", "~> 2.7"

# Added at 2018-07-17 08:39:32 -0400 by teja:
gem "business_time", "~> 0.9.3"
