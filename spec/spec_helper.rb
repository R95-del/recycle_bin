# frozen_string_literal: true

require "bundler/setup"

# Load Rails components needed for testing
require "active_record"
require "active_support"
require "active_support/core_ext"

# Load the gem first
require "recycle_bin"

# Configure ActiveRecord for testing
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

# Create a test table
ActiveRecord::Schema.define do
  create_table :test_models do |t|
    t.string :name
    t.datetime :deleted_at
    t.timestamps
  end
end

# Test model - now that RecycleBin is loaded
class TestModel < ActiveRecord::Base
  include RecycleBin::SoftDeletable
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Clean up database between tests
  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
