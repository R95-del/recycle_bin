# frozen_string_literal: true

module RecycleBin
  class TrashController < ApplicationController
    before_action :load_deleted_items_with_pagination, only: [:index]
    before_action :find_item, only: %i[show restore destroy]

    def index
      # Apply filters to the relation before pagination
      @filtered_items = filter_items_relation(@all_deleted_items_relation)

      # Get model types for filter buttons (from all items, not just current page)
      @model_types = get_all_model_types

      # Apply pagination to the filtered relation
      @current_page = (params[:page] || 1).to_i
      @per_page = (params[:per_page] || RecycleBin.config.items_per_page || 25).to_i

      # Ensure per_page is within reasonable bounds
      @per_page = [[25, @per_page].max, 1000].min

      # Calculate pagination
      @total_count = @filtered_items.count
      @total_pages = (@total_count.to_f / @per_page).ceil
      @current_page = [@current_page, @total_pages].min if @total_pages.positive?
      @current_page = 1 if @current_page < 1

      # Get items for current page
      offset = (@current_page - 1) * @per_page
      @deleted_items = @filtered_items.offset(offset).limit(@per_page).to_a

      # Sort by deletion time (most recent first) - only for current page to maintain performance
      @deleted_items.sort_by!(&:deleted_at).reverse!
    end

    def show
      @original_attributes = @item.attributes.except('deleted_at')
      @associations = load_associations(@item)
      @item_memory_size = calculate_item_memory_size(@item)
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

    def load_deleted_items_with_pagination
      # Create a union query for all soft-deletable models
      @all_deleted_items_relation = build_deleted_items_relation
    end

    def build_deleted_items_relation
      relations = []

      RecycleBin.models_with_soft_delete.each do |model_name|
        model = model_name.constantize
        if model.respond_to?(:deleted) && model.table_exists?
          # Add model type info to the query for filtering
          relation = model.deleted.select("#{model.table_name}.*, '#{model_name}' as model_type")
          relations << relation
        end
      rescue => e
        Rails.logger.debug "Skipping model #{model_name}: #{e.message}"
        next
      end

      # If we have relations, combine them; otherwise return empty relation
      if relations.any?
        # For now, we'll work with arrays since UNION queries are complex across different models
        # Convert relations to arrays and combine
        combined_items = []
        relations.each do |relation|
          combined_items.concat(relation.to_a)
        end

        # Return a custom object that acts like an ActiveRecord relation
        DeletedItemsCollection.new(combined_items)
      else
        DeletedItemsCollection.new([])
      end
    end

    def filter_items_relation(items_collection)
      filtered_items = items_collection.items

      filtered_items = filter_by_type(filtered_items) if params[:type].present?
      filtered_items = filter_by_time(filtered_items) if params[:time].present?

      DeletedItemsCollection.new(filtered_items)
    end

    def filter_by_type(items)
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

    def get_all_model_types
      all_items = build_deleted_items_relation.items
      all_items.map { |item| item.class.name }.uniq.sort
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

    def calculate_item_memory_size(item)
      # Simple calculation of item memory footprint
      item.attributes.to_s.bytesize
    rescue
      0
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

    def trash_index_path
      recycle_bin.root_path
    rescue StandardError
      root_path
    end
  end

  # Helper class to work with combined deleted items from different models
  class DeletedItemsCollection
    attr_reader :items

    def initialize(items)
      @items = items || []
    end

    def count
      @items.count
    end

    def offset(num)
      DeletedItemsCollection.new(@items.drop(num))
    end

    def limit(num)
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

    def empty?
      @items.empty?
    end

    def any?
      @items.any?
    end
  end
end
