# frozen_string_literal: true

module RecycleBin
  # Main controller for handling trash/recycle bin operations
  # Provides CRUD operations for soft-deleted records
  class TrashController < ApplicationController
    # Set up callbacks for actions that need specific trashed items
    before_action :set_trashed_item, only: %i[show restore destroy]
    # Authenticate user if authentication system is available
    # before_action :authenticate_user!, if: :user_authentication_required?
    # Handle errors gracefully
    rescue_from StandardError, with: :handle_recycle_bin_error

    # GET /recycle_bin/trash
    # Lists all trashed items from all models that include SoftDeletable
    def index
      # Fetch all trashed items across all models
      @trashed_items = fetch_all_trashed_items
      # Add pagination support if Kaminari gem is available
      @trashed_items = @trashed_items.page(params[:page]).per(20) if defined?(Kaminari)

      # Always return JSON for now (since we don't have views yet)
      render json: format_trashed_items_for_json(@trashed_items)
    end

    # GET /recycle_bin/trash/:model_type/:id
    # Shows details of a specific trashed item
    def show
      # @trashed_item is set by before_action callback
      # Always return JSON for now (since we don't have views yet)
      render json: format_single_item_for_json(@trashed_item)
    end

    # PATCH /recycle_bin/trash/:model_type/:id/restore
    # Restores a trashed item back to active state
    def restore
      # Check if the item supports restoration
      if @trashed_item.respond_to?(:restore)
        @trashed_item.restore
      else
        # For now, manually restore by setting deleted_at to nil
        @trashed_item.update!(deleted_at: nil)
      end
      success_message = "#{@trashed_item.class.name} has been restored successfully."
      render json: { message: success_message, status: 'success' }
    rescue StandardError => e
      render json: { message: "Unable to restore this item: #{e.message}", status: 'error' },
             status: :unprocessable_entity
    end

    # DELETE /recycle_bin/trash/:model_type/:id
    # Permanently deletes a trashed item (cannot be undone)
    def destroy
      model_name = @trashed_item.class.name
      @trashed_item.destroy!
      success_message = "#{model_name} has been permanently deleted."
      render json: { message: success_message, status: 'success' }
    end

    # PATCH /recycle_bin/trash/bulk_restore
    # Restores multiple trashed items at once
    # Expects: model_type and comma-separated ids
    def bulk_restore
      model_class = params[:model_type].constantize
      ids = params[:ids].split(',')

      restored_count = 0
      ids.each do |id|
        item = model_class.unscoped.where.not(deleted_at: nil).find_by(id: id)
        next unless item

        if item.respond_to?(:restore)
          item.restore
        else
          item.update!(deleted_at: nil)
        end
        restored_count += 1
      end

      success_message = "#{restored_count} items have been restored."
      render json: { message: success_message, restored_count: restored_count, status: 'success' }
    end

    # DELETE /recycle_bin/trash/bulk_destroy
    # Permanently deletes multiple trashed items at once
    # Expects: model_type and comma-separated ids
    def bulk_destroy
      model_class = params[:model_type].constantize
      ids = params[:ids].split(',')

      destroyed_count = 0
      ids.each do |id|
        item = model_class.unscoped.where.not(deleted_at: nil).find_by(id: id)
        if item
          item.destroy!
          destroyed_count += 1
        end
      end

      success_message = "#{destroyed_count} items have been permanently deleted."
      render json: { message: success_message, destroyed_count: destroyed_count, status: 'success' }
    end

    private

    # Find and set the trashed item based on model_type and id parameters
    # Used by before_action for show, restore, and destroy actions
    def set_trashed_item
      model_class = params[:model_type].constantize
      @trashed_item = model_class.unscoped.where.not(deleted_at: nil).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { message: 'Item not found in trash.', status: 'error' }, status: :not_found
    rescue NameError
      render json: { message: 'Invalid model type specified.', status: 'error' }, status: :bad_request
    end

    # Fetches all trashed items from all models that include SoftDeletable
    # Returns an array of hashes with item details
    def fetch_all_trashed_items
      trashed_items = []

      # Get all models that include SoftDeletable
      soft_deletable_models.each do |model_class|
        # Fetch deleted records with a reasonable limit to prevent memory issues
        # Use unscoped to bypass the default scope that excludes deleted records
        deleted_records = model_class.unscoped.where.not(deleted_at: nil).limit(100)
        deleted_records.each do |record|
          trashed_items << {
            id: record.id,
            model_type: model_class.name,
            model_name: model_class.name.humanize,
            display_name: record_display_name(record),
            deleted_at: record.deleted_at,
            record: record
          }
        end
      rescue StandardError => e
        # Skip models that cause errors (like ActionText internal models)
        Rails.logger&.warn "Skipping model #{model_class.name}: #{e.message}"
        next
      end

      # Sort by deleted_at desc (most recently deleted first)
      trashed_items.sort_by { |item| item[:deleted_at] }.reverse
    end

    # Discovers all ActiveRecord models that include RecycleBin::SoftDeletable
    # Returns an array of model classes
    def soft_deletable_models
      models = []
      Rails.application.eager_load!

      ActiveRecord::Base.descendants.each do |model|
        # Skip abstract models and models without proper table setup
        next if model.abstract_class?

        # Skip ActionText internal models
        next if model.name.start_with?('ActionText::', 'ActionMailbox::', 'ActiveStorage::')

        # Skip models that don't have a table configured
        begin
          next unless model.table_exists?
        rescue StandardError => e
          Rails.logger&.warn "Skipping model #{model.name}: #{e.message}"
          next
        end

        # Only include models that have deleted_at column
        models << model if model.column_names.include?('deleted_at')
      end

      models
    rescue StandardError => e
      Rails.logger&.error "Error discovering soft deletable models: #{e.message}"
      []
    end

    # Generates a user-friendly display name for a record
    # Tries common attributes before falling back to "ModelName #ID"
    def record_display_name(record)
      # Try common attribute names for display
      %i[name title subject email username].each do |attr|
        return record.send(attr) if record.respond_to?(attr) && record.send(attr).present?
      end

      # Fallback to model name with ID
      "#{record.class.name} ##{record.id}"
    end

    # Formats trashed items array for JSON API response
    def format_trashed_items_for_json(items)
      {
        trashed_items: items.map do |item|
          {
            id: item[:id],
            model_type: item[:model_type],
            model_name: item[:model_name],
            display_name: item[:display_name],
            deleted_at: item[:deleted_at],
            restore_url: restore_trash_item_url(item[:model_type], item[:id]),
            destroy_url: destroy_trash_item_url(item[:model_type], item[:id])
          }
        end,
        total_count: items.size
      }
    end

    # Formats a single trashed item for JSON API response
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
  end
end
