# frozen_string_literal: true

require_relative 'recycle_bin/version'
require_relative 'recycle_bin/soft_deletable'

# Only require Rails components if Rails is present
require_relative 'recycle_bin/engine' if defined?(Rails)

# RecycleBin provides soft delete functionality for Rails applications.
# It adds a "recycle bin" feature where deleted records are marked as deleted
# instead of being permanently removed from the database.
module RecycleBin
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

  # Improved stats for better performance
  def self.stats
    return {} unless defined?(Rails) && Rails.application

    {
      deleted_items: count_deleted_items,
      models_with_soft_delete: models_with_soft_delete,
      deleted_today: count_deleted_items_today,
      deleted_this_week: count_deleted_items_this_week
    }
  end

  def self.count_deleted_items
    total = 0
    models_with_soft_delete.each do |model_name|
      total += count_deleted_items_for_model(model_name)
    end
    total
  rescue StandardError => e
    log_debug_message("Error counting deleted items: #{e.message}")
    0
  end

  def self.count_deleted_items_today
    total = 0
    models_with_soft_delete.each do |model_name|
      total += count_deleted_items_for_model_since(model_name, 1.day.ago)
    end
    total
  rescue StandardError => e
    log_debug_message("Error counting today's deleted items: #{e.message}")
    0
  end

  def self.count_deleted_items_this_week
    total = 0
    models_with_soft_delete.each do |model_name|
      total += count_deleted_items_for_model_since(model_name, 1.week.ago)
    end
    total
  rescue StandardError => e
    log_debug_message("Error counting this week's deleted items: #{e.message}")
    0
  end

  def self.count_deleted_items_for_model(model_name)
    model = model_name.constantize
    model.respond_to?(:deleted) ? model.deleted.count : 0
  rescue StandardError => e
    log_debug_message("Error counting deleted items for #{model_name}: #{e.message}")
    0
  end

  def self.count_deleted_items_for_model_since(model_name, since_time)
    model = model_name.constantize
    if model.respond_to?(:deleted)
      model.deleted.where('deleted_at >= ?', since_time).count
    else
      0
    end
  rescue StandardError => e
    log_debug_message("Error counting deleted items for #{model_name} since #{since_time}: #{e.message}")
    0
  end

  def self.models_with_soft_delete
    return [] unless rails_application_available?

    # In test environment, we might not need to eager load
    Rails.application.eager_load! if Rails.application.respond_to?(:eager_load!)

    find_soft_deletable_models
  end

  def self.rails_application_available?
    defined?(Rails) && Rails.application
  end

  def self.find_soft_deletable_models
    return [] unless defined?(ActiveRecord)

    ActiveRecord::Base.descendants.filter_map do |model|
      model_name_if_soft_deletable(model)
    end.compact
  rescue StandardError => e
    log_debug_message("Error finding soft deletable models: #{e.message}")
    []
  end

  def self.model_name_if_soft_deletable(model)
    return nil if model.abstract_class? || !model.table_exists?

    model.name if model_has_soft_delete_capability?(model)
  rescue StandardError => e
    log_debug_message("Skipping model #{model.name}: #{e.message}")
    nil
  end

  def self.model_has_soft_delete_capability?(model)
    model.column_names.include?('deleted_at') && model.respond_to?(:deleted)
  end

  # Extract debug logging to reduce duplication
  def self.log_debug_message(message)
    Rails.logger.debug(message) if defined?(Rails) && Rails.logger
  end

  # Get all deleted items across all models (for advanced queries)
  def self.all_deleted_items(limit: nil, offset: nil, order_by: :deleted_at, order_direction: :desc)
    all_items = []

    models_with_soft_delete.each do |model_name|
      model = model_name.constantize
      if model.respond_to?(:deleted)
        items = model.deleted.to_a
        all_items.concat(items)
      end
    rescue StandardError => e
      log_debug_message("Error loading deleted items for #{model_name}: #{e.message}")
    end

    # Sort items
    sorted_items = all_items.sort_by { |item| item.send(order_by) }
    sorted_items.reverse! if order_direction == :desc

    # Apply offset and limit
    sorted_items = sorted_items.drop(offset) if offset&.positive?

    sorted_items = sorted_items.first(limit) if limit&.positive?

    sorted_items
  rescue StandardError => e
    log_debug_message("Error getting all deleted items: #{e.message}")
    []
  end

  # Configuration class for RecycleBin
  class Configuration
    attr_accessor :enable_web_interface, :items_per_page, :ui_theme,
                  :auto_cleanup_after, :current_user_method, :max_items_per_page,
                  :search_settings, :export_settings, :error_logging_service,
                  :enable_advanced_filters, :enable_search_highlighting,
                  :max_search_results, :search_timeout, :enable_export,
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
        search_timeout: 30.seconds,
        enable_fuzzy_search: false,
        min_search_length: 2
      }

      # Export settings
      @export_settings = {
        enable_csv_export: true,
        enable_json_export: true,
        max_export_items: 10_000,
        export_timeout: 5.minutes,
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
      validate_configuration
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

      errors.empty?
    end

    def errors
      validate_configuration
      []
    end
  end
end
