# frozen_string_literal: true

module RecycleBin
  # Main controller for handling trash/recycle bin operations
  # Provides CRUD operations for soft-deleted records
  class TrashController < ApplicationController
    before_action :set_trashed_item, only: %i[show restore destroy]
    rescue_from StandardError, with: :handle_recycle_bin_error

    # GET /recycle_bin/trash
    def index
      @trashed_items = fetch_all_trashed_items
      @trashed_items = paginate_items(@trashed_items)

      render json: format_trashed_items_for_json(@trashed_items)
    end

    # GET /recycle_bin/trash/:model_type/:id
    def show
      render json: format_single_item_for_json(@trashed_item)
    end

    # PATCH /recycle_bin/trash/:model_type/:id/restore
    def restore
      restore_item(@trashed_item)
      success_message = "#{@trashed_item.class.name} has been restored successfully."
      render json: { message: success_message, status: 'success' }
    rescue => e
      render json: {
        message: "Unable to restore this item: #{e.message}",
        status: 'error'
      }, status: :unprocessable_entity
    end

    # DELETE /recycle_bin/trash/:model_type/:id
    def destroy
      model_name = @trashed_item.class.name
      @trashed_item.destroy!
      success_message = "#{model_name} has been permanently deleted."
      render json: { message: success_message, status: 'success' }
    end

    # PATCH /recycle_bin/trash/bulk_restore
    def bulk_restore
      result = perform_bulk_operation(:restore)
      render json: {
        message: "#{result[:count]} items have been restored.",
        restored_count: result[:count],
        status: 'success'
      }
    end

    # DELETE /recycle_bin/trash/bulk_destroy
    def bulk_destroy
      result = perform_bulk_operation(:destroy)
      render json: {
        message: "#{result[:count]} items have been permanently deleted.",
        destroyed_count: result[:count],
        status: 'success'
      }
    end

    private

    def set_trashed_item
      model_class = params[:model_type].constantize
      @trashed_item = find_trashed_item(model_class, params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { message: 'Item not found in trash.', status: 'error' }, status: :not_found
    rescue NameError
      render json: { message: 'Invalid model type specified.', status: 'error' }, status: :bad_request
    end

    def find_trashed_item(model_class, id)
      model_class.unscoped.where.not(deleted_at: nil).find(id)
    end

    def fetch_all_trashed_items
      trashed_items = []

      soft_deletable_models.each do |model_class|
        items = fetch_model_trashed_items(model_class)
        trashed_items.concat(items)
      end

      sort_trashed_items(trashed_items)
    end

    def fetch_model_trashed_items(model_class)
      deleted_records = model_class.unscoped.where.not(deleted_at: nil).limit(100)
      build_trashed_items_array(deleted_records)
    rescue => e
      log_model_skip_warning(model_class, e)
      []
    end

    def build_trashed_items_array(records)
      records.map do |record|
        {
          id: record.id,
          model_type: record.class.name,
          model_name: record.class.name.humanize,
          display_name: record_display_name(record),
          deleted_at: record.deleted_at,
          record: record
        }
      end
    end

    def sort_trashed_items(items)
      items.sort_by { |item| item[:deleted_at] }.reverse
    end

    def soft_deletable_models
      models = []
      Rails.application.eager_load!

      ActiveRecord::Base.descendants.each do |model|
        models << model if valid_soft_deletable_model?(model)
      end

      models
    rescue => e
      log_model_discovery_error(e)
      []
    end

    def valid_soft_deletable_model?(model)
      return false if model.abstract_class?
      return false if internal_rails_model?(model)
      return false unless model_has_valid_table?(model)

      model.column_names.include?('deleted_at')
    end

    def internal_rails_model?(model)
      model.name.start_with?('ActionText::', 'ActionMailbox::', 'ActiveStorage::')
    end

    def model_has_valid_table?(model)
      model.table_exists?
    rescue => e
      log_model_skip_warning(model, e)
      false
    end

    def record_display_name(record)
      display_attributes = %i[name title subject email username]

      display_attributes.each do |attr|
        value = get_record_attribute_value(record, attr)
        return value if value.present?
      end

      "#{record.class.name} ##{record.id}"
    end

    def get_record_attribute_value(record, attribute)
      return nil unless record.respond_to?(attribute)

      record.send(attribute)
    end

    def restore_item(item)
      if item.respond_to?(:restore)
        item.restore
      else
        item.update!(deleted_at: nil)
      end
    end

    def perform_bulk_operation(operation)
      model_class = params[:model_type].constantize
      ids = parse_bulk_ids
      count = 0

      ids.each do |id|
        item = find_bulk_item(model_class, id)
        next unless item

        perform_item_operation(item, operation)
        count += 1
      end

      { count: count }
    end

    def parse_bulk_ids
      params[:ids].split(',')
    end

    def find_bulk_item(model_class, id)
      model_class.unscoped.where.not(deleted_at: nil).find_by(id: id)
    end

    def perform_item_operation(item, operation)
      case operation
      when :restore
        restore_item(item)
      when :destroy
        item.destroy!
      end
    end

    def paginate_items(items)
      return items unless defined?(Kaminari)

      items.page(params[:page]).per(20)
    end

    def format_trashed_items_for_json(items)
      {
        trashed_items: build_trashed_items_json(items),
        total_count: items.size
      }
    end

    def build_trashed_items_json(items)
      items.map { |item| build_single_trashed_item_json(item) }
    end

    def build_single_trashed_item_json(item)
      {
        id: item[:id],
        model_type: item[:model_type],
        model_name: item[:model_name],
        display_name: item[:display_name],
        deleted_at: item[:deleted_at],
        restore_url: restore_trash_item_url(item[:model_type], item[:id]),
        destroy_url: destroy_trash_item_url(item[:model_type], item[:id])
      }
    end

    def format_single_item_for_json(item)
      {
        id: item.id,
        model_type: item.class.name,
        model_name: item.class.name.humanize,
        display_name: record_display_name(item),
        deleted_at: item.deleted_at,
        attributes: item.attributes.except('deleted_at'),
        restore_url: restore_trash_item_url(item.class.name, item.id),
        destroy_url: destroy_trash_item_url(item.class.name, item.id)
      }
    end

    def log_model_skip_warning(model_class, error)
      return unless Rails.logger

      Rails.logger.warn "Skipping model #{model_class.name}: #{error.message}"
    end

    def log_model_discovery_error(error)
      return unless Rails.logger

      Rails.logger.error "Error discovering soft deletable models: #{error.message}"
    end
  end
end
