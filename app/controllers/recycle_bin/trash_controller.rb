# frozen_string_literal: true

module RecycleBin
  class TrashController < ApplicationController
    before_action :load_deleted_items, only: [:index]
    before_action :find_item, only: %i[show restore destroy]

    def index
      # Apply filters
      @deleted_items = filter_items(@deleted_items)

      # Get model types for filter buttons
      @model_types = @deleted_items.map { |item| item.class.name }.uniq.sort

      # Apply pagination (since @deleted_items is an Array, we need to handle this differently)
      items_per_page = RecycleBin.config.items_per_page || 25
      @deleted_items = @deleted_items.first(items_per_page)
    end

    def show
      @original_attributes = @item.attributes.except('deleted_at')
      @associations = load_associations(@item)
    end

    def restore
      if @item.restore
        redirect_to root_path, notice: "#{@item.class.name} successfully restored!"
      else
        redirect_to root_path, alert: "Failed to restore #{@item.class.name}."
      end
    rescue => e
      Rails.logger.error "Error restoring item: #{e.message}"
      redirect_to root_path, alert: "Failed to restore #{@item.class.name}."
    end

    def destroy
      model_name = @item.class.name
      if @item.destroy!
        redirect_to root_path, notice: "#{model_name} permanently deleted."
      else
        redirect_to root_path, alert: "Failed to delete #{model_name}."
      end
    rescue => e
      Rails.logger.error "Error deleting item: #{e.message}"
      redirect_to root_path, alert: "Failed to delete #{model_name}."
    end

    def bulk_restore
      restored_count = 0
      selected_items = parse_bulk_selection

      selected_items.each do |model_class, id|
        next unless model_class && id

        model = safe_constantize_model(model_class)
        next unless model.respond_to?(:with_deleted)

        item = model.with_deleted.find_by(id: id)
        restored_count += 1 if item&.restore
      end

      redirect_to trash_index_path, notice: "#{restored_count} items restored successfully!"
    end

    def bulk_destroy
      destroyed_count = 0
      selected_items = parse_bulk_selection

      selected_items.each do |model_class, id|
        next unless model_class && id

        model = safe_constantize_model(model_class)
        next unless model.respond_to?(:with_deleted)

        item = model.with_deleted.find_by(id: id)
        destroyed_count += 1 if item&.destroy!
      end

      redirect_to trash_index_path, notice: "#{destroyed_count} items permanently deleted."
    end

    private

    def load_deleted_items
      @deleted_items = []

      # Use the safer method from RecycleBin module
      RecycleBin.models_with_soft_delete.each do |model_name|
        model = model_name.constantize
        if model.respond_to?(:deleted)
          # Get up to 100 items per model to avoid memory issues
          deleted_records = model.deleted.limit(100).to_a
          @deleted_items.concat(deleted_records)
        end
      rescue => e
        Rails.logger.debug "Skipping model #{model_name}: #{e.message}"
        next
      end

      # Sort by deletion time (most recent first)
      @deleted_items.sort_by!(&:deleted_at).reverse!
    end

    def filter_items(items)
      items = filter_by_type(items) if params[:type].present?
      items = filter_by_time(items) if params[:time].present?
      items
    end

    def filter_by_type(items)
      # RuboCop prefers this approach over direct class name comparison
      # We need to compare against the string parameter from URL params
      target_class_name = params[:type]
      items.select { |item| item.class.name == target_class_name }
    end

    def filter_by_time(items)
      cutoff_time = case params[:time]
                    when 'today' then 1.day.ago
                    when 'week' then 1.week.ago
                    when 'month' then 1.month.ago
                    else return items
                    end

      items.select { |item| item.deleted_at >= cutoff_time }
    end

    def find_item
      model_class = safe_constantize_model(params[:model_type])

      unless model_class.respond_to?(:with_deleted)
        redirect_to trash_index_path, alert: 'Invalid model type.'
        return
      end

      @item = model_class.with_deleted.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to trash_index_path, alert: 'Item not found.'
    end

    def load_associations(item)
      associations = {}

      item.class.reflect_on_all_associations.each do |association|
        next if association.macro == :belongs_to

        related_items = safely_load_association(item, association)
        associations[association.name] = related_items if related_items.present?
      end

      associations
    end

    def safely_load_association(item, association)
      related_items = item.send(association.name)
      limit_association_items(related_items)
    rescue => e
      Rails.logger.debug "Skipping association #{association.name}: #{e.message}"
      nil
    end

    def limit_association_items(related_items)
      return Array(related_items) unless related_items.respond_to?(:limit)

      if related_items.respond_to?(:first)
        related_items.is_a?(Array) ? related_items.first(10) : related_items
      else
        related_items.limit(10)
      end
    end

    def parse_bulk_selection
      selected_items = extract_selected_items
      return [] unless selected_items.is_a?(Array)

      parse_item_strings(selected_items)
    end

    def extract_selected_items
      selected_items = params[:selected_items]

      return JSON.parse(selected_items) if selected_items.is_a?(String)

      selected_items
    rescue JSON::ParserError
      []
    end

    def parse_item_strings(selected_items)
      parsed_items = selected_items.filter_map do |item_string|
        parse_single_item(item_string)
      end

      parsed_items.reject { |model_class, id| model_class.blank? || id.zero? }
    end

    def parse_single_item(item_string)
      return nil unless item_string.is_a?(String)

      model_class, id = item_string.split(':')
      return nil if model_class.blank? || id.blank?

      [model_class, id.to_i]
    end

    # Helper method to generate trash index path
    def trash_index_path
      recycle_bin.root_path
    rescue StandardError
      root_path
    end
  end
end
