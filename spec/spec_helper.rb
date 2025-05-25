# frozen_string_literal: true

require 'bundler/setup'
require 'recycle_bin'

# Only set up database if we're running Rails-specific tests
if ENV['RAILS_ENV'] != 'false'
  begin
    require 'active_record'
    require 'sqlite3'

    # Configure ActiveRecord for testing
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: ':memory:'
    )

    # Create a test table for our specs
    ActiveRecord::Schema.define do
      create_table :test_models, force: true do |t|
        t.string :name
        t.datetime :deleted_at
        t.timestamps
      end
    end

    # Test model for specs
    class TestModel < ActiveRecord::Base
      include RecycleBin::SoftDeletable
    end
  rescue LoadError => e
    puts "Skipping ActiveRecord setup: #{e.message}"
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Clean up database between tests (only if ActiveRecord is loaded)
  if defined?(ActiveRecord)
    config.before(:each) do
      # Clean up any existing test data
      TestModel.with_deleted.delete_all if defined?(TestModel)
    end

    config.around(:each) do |example|
      if ActiveRecord::Base.connection.transaction_open?
        example.run
      else
        ActiveRecord::Base.transaction do
          example.run
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end
