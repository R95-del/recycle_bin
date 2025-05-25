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
                  :auto_cleanup_after, :current_user_method, :max_items_per_page

    def initialize
      @enable_web_interface = true
      @items_per_page = 25
      @max_items_per_page = 1000
      @ui_theme = 'default'
      @auto_cleanup_after = nil
      @current_user_method = :current_user
    end

    def authorize_with(&block)
      @authorization_method = block
    end

    def authorization_method
      @authorization_method || proc { true }
    end
  end
end
