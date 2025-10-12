# frozen_string_literal: true

require 'bundler/setup'
require 'logger'

# Try to load rails/engine for the Engine class
begin
  require 'rails/engine'
rescue LoadError
  # If rails/engine is not available, create a simple mock
  module Rails
    class Engine
      def self.isolate_namespace(_namespace)
        # Mock implementation
      end
    end
  end
end

# Mock Rails module methods for testing
module Rails
  class << self
    def application
      @application ||= Struct.new(:eager_load!).new
    end

    def logger
      @logger ||= Logger.new($stdout, level: Logger::WARN)
    end

    def respond_to_missing?(_method_name, _include_private = false)
      true
    end

    def method_missing(_method_name, *_args, &_block)
      # Handle any Rails.xyz calls gracefully
      nil
    end
  end
end

# Mock ActiveJob for testing
unless defined?(ActiveJob)
  module ActiveJob
    class Base
      def self.queue_as(_queue_name)
        # Mock implementation
      end

      def self.retry_on(*_args)
        # Mock implementation
      end

      def self.respond_to?(_method_name)
        true
      end

      def queue_name
        'default'
      end

      def logger
        @logger ||= Logger.new($stdout)
      end
    end
  end
end

# Prevent loading the engine in test mode
ENV['RECYCLE_BIN_SKIP_ENGINE'] = 'true'

# Load only the core components for testing
require_relative '../lib/recycle_bin'

# Add the DeletedItemsCollection class for testing
module RecycleBin
  class DeletedItemsCollection
    attr_reader :items

    def initialize(items)
      @items = items || []
    end

    def count
      @items.count
    end

    def offset(num)
      return DeletedItemsCollection.new(@items) if num < 0

      DeletedItemsCollection.new(@items.drop(num))
    end

    def limit(num)
      return DeletedItemsCollection.new([]) if num < 0

      DeletedItemsCollection.new(@items.first(num))
    end

    def to_a
      @items
    end

    def each(&block)
      @items.each(&block)
    end

    def map(&block)
      @items.map(&block)
    end

    def select(&block)
      DeletedItemsCollection.new(@items.select(&block))
    end

    def reject(&block)
      DeletedItemsCollection.new(@items.reject(&block))
    end

    def empty?
      @items.empty?
    end

    def any?
      @items.any?
    end
  end

  # Add the Engine class for testing
  class Engine
    def self.config
      @config ||= begin
        # Create a simple config object with the methods we need
        config_obj = Object.new

        # Mock paths
        paths_obj = Object.new
        def paths_obj.[](key)
          case key
          when 'app/controllers', 'app/views', 'app/helpers', 'app/assets', 'lib'
            ['recycle_bin']
          else
            []
          end
        end

        # Mock generators
        generators_obj = Object.new
        def generators_obj.test_framework=(value); end
        def generators_obj.assets=(value); end
        def generators_obj.helper=(value); end

        # Mock app generators
        app_generators_obj = Object.new
        def app_generators_obj.test_framework=(value); end
        def app_generators_obj.assets=(value); end
        def app_generators_obj.helper=(value); end

        # Set up the config object methods
        config_obj.instance_eval do
          @paths_obj = paths_obj
          @generators_obj = generators_obj
          @app_generators_obj = app_generators_obj

          def paths
            @paths_obj
          end

          def generators
            @generators_obj
          end

          def app_generators
            @app_generators_obj
          end
        end

        config_obj
      end
    end

    def self.ancestors
      [self, Rails::Engine, Object, Kernel, BasicObject]
    end
  end

  # Add the ApplicationController class for testing
  class ApplicationController
    def self.before_action(*args); end
    def self.skip_before_action(*args); end

    def current_user
      @current_user ||= double('User', admin?: true)
    end

    def redirect_to(path)
      @redirect_path = path
    end

    def render(*args)
      @render_args = args
    end

    def flash
      @flash ||= {}
    end

    def params
      @params ||= {}
    end

    def request
      @request ||= double('Request', format: double('Format', html?: true))
    end

    def response
      @response ||= double('Response', content_type: 'text/html')
    end

    def log_error(error)
      # Mock error logging
    end
  end

  # Add the TrashController class for testing
  class TrashController < ApplicationController
    def index
      # Mock index action
    end

    def show
      # Mock show action
    end

    def restore
      # Mock restore action
    end

    def destroy
      # Mock destroy action
    end

    def bulk_restore
      # Mock bulk restore action
    end

    def bulk_destroy
      # Mock bulk destroy action
    end

    def trash_index_path
      '/trash'
    end
  end
end

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

      # Mock the where method to handle time conditions
      def self.where(conditions)
        if conditions.is_a?(String) && conditions.include?('deleted_at >= ?')
          # Handle time-based queries
          time_param = conditions.match(/deleted_at >= \?/).post_match.strip
          if time_param == '1.day.ago'
            all_records.select { |r| r.deleted_at && r.deleted_at >= 1.day.ago }
          elsif time_param == '1.week.ago'
            all_records.select { |r| r.deleted_at && r.deleted_at >= 1.week.ago }
          else
            all_records
          end
        elsif conditions == { deleted_at: :not_nil }
          all_records.select { |r| r.deleted_at.present? }
        elsif conditions == { deleted_at: :nil }
          all_records.select { |r| r.deleted_at.nil? }
        else
          all_records
        end
      end
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

  # Basic RSpec configuration without Rails-specific features
  # Only use infer_spec_type_from_file_location! if available
  config.infer_spec_type_from_file_location! if config.respond_to?(:infer_spec_type_from_file_location!)
  config.use_transactional_fixtures = false if config.respond_to?(:use_transactional_fixtures=)

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
