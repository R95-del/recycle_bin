# frozen_string_literal: true

require_relative 'recycle_bin/version'
require_relative 'recycle_bin/engine' if defined?(Rails)
require_relative 'recycle_bin/soft_deletable'

module RecycleBin
  class Error < StandardError; end

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
    models_with_soft_delete.each do |model|
      total += begin
        model.constantize.deleted.count
      rescue StandardError
        0
      end
    end
    total
  end

  def self.models_with_soft_delete
    Rails.application.eager_load! if defined?(Rails)
    ActiveRecord::Base.descendants.select do |model|
      model.column_names.include?('deleted_at')
    end.map(&:name)
  end
end
