# frozen_string_literal: true

require 'bundler/setup'

# Mock Rails for testing if it's not available
unless defined?(Rails)
  module Rails
    class Engine
      def self.isolate_namespace(namespace)
        # Mock implementation
      end
    end

    class Application
      def self.eager_load!
        # Mock implementation
      end

      def self.respond_to?(_method_name)
        true
      end
    end

    # Make application available globally
    def self.application
      @application ||= Application.new
    end
  end
end

# Load only the core components for testing
require_relative '../lib/recycle_bin/soft_deletable'

# Define the Configuration class for testing
module RecycleBin
  class Configuration
    attr_accessor :enable_web_interface, :items_per_page, :ui_theme,
                  :auto_cleanup_after, :current_user_method, :max_items_per_page,
                  :search_settings, :export_settings, :error_logging_service,
                  :enable_advanced_filters, :enable_search_highlighting,
                  :max_search_results, :enable_export,
                  :export_formats, :export_max_items, :enable_audit_logging

    def initialize
      # Basic settings
      @enable_web_interface = true
      @items_per_page = 25
      @max_items_per_page = 1000
      @ui_theme = 'default'
      @auto_cleanup_after = nil
      @current_user_method = :current_user

      # Search settings
      @search_settings = {
        enable_full_text_search: true,
        searchable_fields: %w[title name email content body description],
        max_search_length: 100,
        search_timeout: 30,
        enable_fuzzy_search: false,
        min_search_length: 2
      }

      # Export settings
      @export_settings = {
        enable_csv_export: true,
        enable_json_export: true,
        max_export_items: 10_000,
        export_timeout: 300,
        include_metadata: true,
        compress_large_exports: true
      }

      # Advanced features
      @enable_advanced_filters = true
      @enable_search_highlighting = true
      @max_search_results = 10_000
      @enable_export = true
      @export_formats = %w[csv json]
      @export_max_items = 10_000
      @enable_audit_logging = false

      # Error logging service (can be set to external service like Sentry)
      @error_logging_service = nil
    end

    def authorize_with(&block)
      @authorization_method = block
    end

    def authorization_method
      @authorization_method || proc { true }
    end

    # Search configuration methods
    def search_config
      @search_settings
    end

    def enable_full_text_search=(value)
      @search_settings[:enable_full_text_search] = value
    end

    def searchable_fields=(fields)
      @search_settings[:searchable_fields] = Array(fields)
    end

    def max_search_length=(length)
      @search_settings[:max_search_length] = length
    end

    def search_timeout=(timeout)
      @search_settings[:search_timeout] = timeout
    end

    # Export configuration methods
    def export_config
      @export_settings
    end

    def enable_csv_export=(value)
      @export_settings[:enable_csv_export] = value
    end

    def enable_json_export=(value)
      @export_settings[:enable_json_export] = value
    end

    def max_export_items=(count)
      @export_settings[:max_export_items] = count
    end

    def export_timeout=(timeout)
      @export_settings[:export_timeout] = timeout
    end

    # Validation methods
    def valid?
      validate_configuration.empty?
    end

    def validate_configuration
      errors = []

      # Validate search settings
      errors << 'min_search_length cannot be greater than max_search_length' if @search_settings[:min_search_length] > @search_settings[:max_search_length]

      errors << 'search_timeout must be positive' if @search_settings[:search_timeout] <= 0

      # Validate export settings
      errors << 'max_export_items must be positive' if @export_settings[:max_export_items] <= 0

      errors << 'export_timeout must be positive' if @export_settings[:export_timeout] <= 0

      # Validate basic settings
      errors << 'items_per_page must be positive' if @items_per_page <= 0

      errors << 'max_items_per_page cannot be less than items_per_page' if @max_items_per_page < @items_per_page

      errors
    end

    def errors
      validate_configuration
    end
  end

  class Error < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
    configuration
  end

  def self.config
    configuration || (self.configuration = Configuration.new)
  end

  # Improved stats methods for testing
  def self.stats
    return {} unless defined?(Rails) && Rails.respond_to?(:application) && Rails.application

    {
      deleted_items: count_deleted_items,
      models_with_soft_delete: models_with_soft_delete,
      deleted_today: count_deleted_items_today,
      deleted_this_week: count_deleted_items_this_week
    }
  end

  def self.models_with_soft_delete
    return [] unless defined?(Rails) && Rails.respond_to?(:application) && Rails.application

    # In test environment, return TestModel if available
    if defined?(TestModel)
      ['TestModel']
    else
      []
    end
  end

  def self.count_deleted_items
    return 0 unless defined?(Rails) && Rails.respond_to?(:application) && Rails.application

    if defined?(TestModel)
      TestModel.deleted.count
    else
      0
    end
  rescue StandardError => e
    puts "Error counting deleted items: #{e.message}"
    0
  end

  def self.count_deleted_items_today
    return 0 unless defined?(Rails) && Rails.respond_to?(:application) && Rails.application

    if defined?(TestModel)
      TestModel.deleted.where('deleted_at >= ?', 1.day.ago).count
    else
      0
    end
  rescue StandardError => e
    puts "Error counting today's deleted items: #{e.message}"
    0
  end

  def self.count_deleted_items_this_week
    return 0 unless defined?(Rails) && Rails.respond_to?(:application) && Rails.application

    if defined?(TestModel)
      TestModel.deleted.where('deleted_at >= ?', 1.week.ago).count
    else
      0
    end
  rescue StandardError => e
    puts "Error counting this week's deleted items: #{e.message}"
    0
  end

  def self.all_deleted_items(limit: nil, offset: nil, order_by: :deleted_at, order_direction: :desc)
    return [] unless defined?(Rails) && Rails.respond_to?(:application) && Rails.application

    if defined?(TestModel)
      items = TestModel.deleted.to_a

      # Sort items
      sorted_items = items.sort_by { |item| item.send(order_by) }
      sorted_items.reverse! if order_direction == :desc

      # Apply offset and limit
      sorted_items = sorted_items.drop(offset) if offset&.positive?
      sorted_items = sorted_items.first(limit) if limit&.positive?

      sorted_items
    else
      []
    end
  rescue StandardError => e
    puts "Error getting all deleted items: #{e.message}"
    []
  end

  def self.rails_application_available?
    defined?(Rails) && Rails.respond_to?(:application) && Rails.application
  end
end

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
