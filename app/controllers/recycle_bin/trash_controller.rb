module RecycleBin
  class TrashController < ApplicationController
    before_action :set_trashed_item, only: [:show, :restore, :destroy]

    def index
      @trashed_items = fetch_all_trashed_items
      @trashed_items = @trashed_items.page(params[:page]).per(20) if defined?(Kaminari)
    end

    def show
      # Individual trashed item view
    end

    def restore
      if @trashed_item.respond_to?(:restore)
        @trashed_item.restore
        redirect_to recycle_bin.trash_index_path, notice: "#{@trashed_item.class.name} has been restored successfully."
      else
        redirect_to recycle_bin.trash_index_path, alert: "Unable to restore this item."
      end
    end

    def destroy
      model_name = @trashed_item.class.name
      @trashed_item.destroy!
      redirect_to recycle_bin.trash_index_path, notice: "#{model_name} has been permanently deleted."
    end

    def bulk_restore
      model_class = params[:model_type].constantize
      ids = params[:ids].split(',')
      
      restored_count = 0
      ids.each do |id|
        item = model_class.deleted.find_by(id: id)
        if item&.respond_to?(:restore)
          item.restore
          restored_count += 1
        end
      end
      
      redirect_to recycle_bin.trash_index_path, notice: "#{restored_count} items have been restored."
    end

    def bulk_destroy
      model_class = params[:model_type].constantize
      ids = params[:ids].split(',')
      
      destroyed_count = 0
      ids.each do |id|
        item = model_class.deleted.find_by(id: id)
        if item
          item.destroy!
          destroyed_count += 1
        end
      end
      
      redirect_to recycle_bin.trash_index_path, notice: "#{destroyed_count} items have been permanently deleted."
    end

    private

    def set_trashed_item
      model_class = params[:model_type].constantize
      @trashed_item = model_class.deleted.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to recycle_bin.trash_index_path, alert: "Item not found in trash."
    end

    def fetch_all_trashed_items
      trashed_items = []
      
      # Get all models that include SoftDeletable
      soft_deletable_models.each do |model_class|
        deleted_records = model_class.deleted.limit(100) # Limit to prevent memory issues
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
      end
      
      # Sort by deleted_at desc
      trashed_items.sort_by { |item| item[:deleted_at] }.reverse
    end

    def soft_deletable_models
      # Find all models that include RecycleBin::SoftDeletable
      models = []
      Rails.application.eager_load!
      
      ActiveRecord::Base.descendants.each do |model|
        if model.included_modules.any? { |m| m.to_s.include?('RecycleBin::SoftDeletable') }
          models << model
        end
      end
      
      models
    end

    def record_display_name(record)
      # Try common attribute names for display
      [:name, :title, :subject, :email, :username].each do |attr|
        return record.send(attr) if record.respond_to?(attr) && record.send(attr).present?
      end
      
      # Fallback to model name with ID
      "#{record.class.name} ##{record.id}"
    end

    # def user_authentication_required?
    #   # Check if Devise or other authentication is available
    #   defined?(Devise) || respond_to?(:current_user)
    # end
  end
end