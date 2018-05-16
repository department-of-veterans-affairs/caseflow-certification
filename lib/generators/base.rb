# Base class for a generator.
#
# The purpose of generators is to easily setup data for testing.
# They are used in a similar way to FactoryGirl, but are also used
# for instrumenting faked dependecies.
#
# They are useful for:
# - Setting up default boilerplate data like ids
# - Setting up and connecting the appropriate data in Fakes
# - Containing complex data fixtures
#
# Each Generator class must implement the `.build(attrs)` method
# which must return an unsaved ActiveRecord object. Generators will
# get the `create(attrs)` method for free by extending Generators::Base
module Generators::Base
  def generate_external_id
    SecureRandom.random_number(1_000_000).to_s
  end

  def generate_first_name
    %w[George John Thomas James Andrew Martin Susan Barack Grace Anne].sample
  end

  def generate_last_name
    %w[Washington King Jefferson Anthony Madison Jackson VanBuren Merica].sample
  end

  def build(*)
    fail "#{self.class.name} must implement .build(attrs)"
  end

  def create(attrs = {})
    build(attrs).tap(&:save!)
  end
end
