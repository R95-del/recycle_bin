# frozen_string_literal: true

require_relative 'recycle_bin/version'
require_relative 'recycle_bin/soft_deletable'

# Only require Rails components if Rails is present
if defined?(Rails)
  require_relative 'recycle_bin/engine'
end

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
  end

  def self.config
    @configuration ||= Configuration.new
  end

  # Simple stats for V1
  def self.stats
    return {} unless defined?(Rails) && Rails.application

    {
      deleted_items: count_deleted_items,
      models_with_soft_delete: models_with_soft_delete
    }
  end

  def self.count_deleted_items
    total = 0
    models_with_soft_delete.each do |model_name|
      begin
        model = model_name.constantize
        total += model.deleted.count if model.respond_to?(:deleted)
      rescue => e
        Rails.logger.debug "Error counting deleted items for #{model_name}: #{e.message}" if defined?(Rails)
      end
    end
    total
  end

  def self.models_with_soft_delete
    return [] unless defined?(Rails) && Rails.application
    
    Rails.application.eager_load!
    
    ActiveRecord::Base.descendants.filter_map do |model|
      # Skip abstract models and models without tables
      next if model.abstract_class?
      next unless model.table_exists?
      
      begin
        # Check if model has deleted_at column and soft delete capability
        if model.column_names.include?('deleted_at') && model.respond_to?(:deleted)
          model.name
        end
      rescue => e
        # Skip models that cause issues (like ActiveStorage::Record)
        Rails.logger.debug "Skipping model #{model.name}: #{e.message}" if defined?(Rails)
        nil
      end
    end.compact
  end

  # Configuration class for RecycleBin
  class Configuration
    attr_accessor :enable_web_interface, :items_per_page, :ui_theme,
                  :auto_cleanup_after, :current_user_method

    def initialize
      @enable_web_interface = true
      @items_per_page = 25
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