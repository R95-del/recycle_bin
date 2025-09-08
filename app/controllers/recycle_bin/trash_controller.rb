# frozen_string_literal: true

module RecycleBin
  class TrashController < ApplicationController
    layout 'recycle_bin/layouts/recycle_bin'
    before_action :load_deleted_items_with_pagination, only: [:index]
    before_action :load_dashboard_data, only: [:dashboard]
    before_action :find_item, only: %i[show restore destroy]

    # Dashboard view - Overview with stats and recent activity
    def dashboard
      respond_to do |format|
        format.html { render :dashboard }
        format.csv { export_to_csv(@all_deleted_items) }
        format.json { export_to_json(@all_deleted_items) }
      end
    end

    # All Items view - Detailed list with filtering
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

      # Handle export requests
      respond_to do |format|
        format.html
        format.csv { export_to_csv(@filtered_items) }
        format.json { export_to_json(@filtered_items) }
      end
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
      log_error('Error restoring item', e, item: @item)
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
      log_error('Error deleting item', e, item: @item)
      redirect_to root_path, alert: "Failed to delete #{model_name}."
    end

    def bulk_restore
      restored_count = 0
      failed_count = 0
      selected_items = parse_bulk_selection

      if selected_items.empty?
        redirect_to trash_index_path, alert: 'No items selected for restoration.'
        return
      end

      selected_items.each do |model_class, id|
        next unless model_class && id

        model = safe_constantize_model(model_class)
        unless model.respond_to?(:with_deleted)
          Rails.logger.warn "Model #{model_class} does not support soft delete"
          failed_count += 1
          next
        end

        item = model.with_deleted.find_by(id: id)
        if item&.restore
          restored_count += 1
          Rails.logger.info "Successfully restored #{model_class}##{id}"
        else
          failed_count += 1
          Rails.logger.warn "Failed to restore #{model_class}##{id}"
        end
      end

      message = "#{restored_count} items restored successfully!"
      message += " (#{failed_count} failed)" if failed_count.positive?

      redirect_to trash_index_path, notice: message
    rescue => e
      log_error('Bulk restore failed', e)
      redirect_to trash_index_path, alert: "Bulk restore failed: #{e.message}"
    end

    def bulk_destroy
      destroyed_count = 0
      failed_count = 0
      selected_items = parse_bulk_selection

      if selected_items.empty?
        redirect_to trash_index_path, alert: 'No items selected for deletion.'
        return
      end

      selected_items.each do |model_class, id|
        next unless model_class && id

        model = safe_constantize_model(model_class)
        unless model.respond_to?(:with_deleted)
          Rails.logger.warn "Model #{model_class} does not support soft delete"
          failed_count += 1
          next
        end

        item = model.with_deleted.find_by(id: id)
        if item&.destroy!
          destroyed_count += 1
          Rails.logger.info "Successfully destroyed #{model_class}##{id}"
        else
          failed_count += 1
          Rails.logger.warn "Failed to destroy #{model_class}##{id}"
        end
      end

      message = "#{destroyed_count} items permanently deleted."
      message += " (#{failed_count} failed)" if failed_count.positive?

      redirect_to trash_index_path, notice: message
    rescue => e
      log_error('Bulk destroy failed', e)
      redirect_to trash_index_path, alert: "Bulk destroy failed: #{e.message}"
    end

    private

    def load_deleted_items_with_pagination
      # Create a union query for all soft-deletable models
      @all_deleted_items_relation = build_deleted_items_relation
    end

    def load_dashboard_data
      # Get all deleted items for dashboard
      @all_deleted_items = RecycleBin.all_deleted_items(limit: 1000).to_a
      @total_count = @all_deleted_items.count
      @model_types = @all_deleted_items.map { |item| item.class.name }.uniq.sort

      # Recent activity (last 10 items)
      @recent_items = @all_deleted_items.sort_by(&:deleted_at).reverse.first(10)

      # Model breakdown for chart
      model_counts = @all_deleted_items.group_by { |item| item.class.name }
      model_data = model_counts.map do |model_name, items|
        count = items.count
        percentage = @total_count.positive? ? (count.to_f / @total_count * 100) : 0
        {
          name: model_name,
          count: count,
          percentage: percentage
        }
      end
      @model_breakdown = model_data.sort_by { |data| -data[:count] }

      # Weekly stats (last 7 days)
      @weekly_stats = if @all_deleted_items.any?
                        calculate_weekly_stats(@all_deleted_items)
                      else
                        []
                      end
    end

    def calculate_weekly_stats(items)
      # Get last 7 days
      days = 7.times.map { |i| (Date.current - i.days) }.reverse

      # Group items by date
      items_by_date = items.group_by { |item| item.deleted_at.to_date }

      # Calculate stats for each day
      max_count = 0
      day_stats = days.map do |date|
        count = items_by_date[date]&.count || 0
        max_count = [max_count, count].max
        {
          day: date.strftime('%a'),
          count: count,
          date: date
        }
      end

      # Calculate percentages
      day_stats.map do |stat|
        stat[:percentage] = max_count.positive? ? (stat[:count].to_f / max_count * 100) : 0
        stat
      end
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
        log_debug("Skipping model #{model_name}: #{e.message}")
        next
      end

      # If we have relations, combine them; otherwise return empty relation
      if relations.any?
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

      # Apply search filter first
      filtered_items = filter_by_search(filtered_items) if params[:search].present?

      # Apply other filters
      filtered_items = filter_by_type(filtered_items) if params[:type].present?
      filtered_items = filter_by_time(filtered_items) if params[:time].present?
      filtered_items = filter_by_user(filtered_items) if params[:deleted_by].present?
      filtered_items = filter_by_size(filtered_items) if params[:size].present?
      filtered_items = filter_by_date_range(filtered_items) if params[:date_from].present? || params[:date_to].present?

      DeletedItemsCollection.new(filtered_items)
    end

    def filter_by_search(items)
      search_term = params[:search].downcase.strip
      return items if search_term.blank?

      items.select do |item|
        # Priority 1: Exact matches in primary title fields (highest relevance)
        primary_fields = %w[title name subject]
        exact_title_match = primary_fields.any? do |field|
          if item.respond_to?(field)
            field_value = item.send(field)
            field_value && field_value.to_s.downcase.strip == search_term
          else
            false
          end
        end

        # Priority 2: Starts with matches in primary fields
        starts_with_match = !exact_title_match && primary_fields.any? do |field|
          if item.respond_to?(field)
            field_value = item.send(field)
            field_value && field_value.to_s.downcase.strip.start_with?(search_term)
          else
            false
          end
        end

        # Priority 3: Contains matches in primary fields (only if search term is 3+ characters)
        primary_contains_match = !exact_title_match && !starts_with_match && search_term.length >= 3 && primary_fields.any? do |field|
          if item.respond_to?(field)
            field_value = item.send(field)
            field_value && field_value.to_s.downcase.include?(search_term)
          else
            false
          end
        end

        # Priority 4: ID exact match
        id_match = !exact_title_match && !starts_with_match && !primary_contains_match && item.id.to_s == search_term

        # Priority 5: Model class name match (only if search term is 3+ characters)
        class_match = !exact_title_match && !starts_with_match && !primary_contains_match && !id_match &&
                      search_term.length >= 3 && item.class.name.downcase.include?(search_term)

        # Only search secondary fields for longer search terms (4+ characters) and as last resort
        secondary_match = false
        if !exact_title_match && !starts_with_match && !primary_contains_match && !id_match && !class_match && search_term.length >= 4
          secondary_fields = %w[email] # Removed content, body, description to reduce false matches
          secondary_match = secondary_fields.any? do |field|
            if item.respond_to?(field)
              field_value = item.send(field)
              field_value && !field_value.to_s.strip.empty? && field_value.to_s.downcase.include?(search_term)
            else
              false
            end
          end
        end

        # Return true if any priority level matches
        exact_title_match || starts_with_match || primary_contains_match || id_match || class_match || secondary_match
      end
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
                    when 'year' then 1.year.ago
                    else return items
                    end

      items.select { |item| item.deleted_at >= cutoff_time }
    end

    def filter_by_user(items)
      user_id = params[:deleted_by]
      return items if user_id.blank?

      items.select do |item|
        # Check if item has user association or deleted_by field
        if item.respond_to?(:user_id)
          item.user_id.to_s == user_id.to_s
        elsif item.respond_to?(:deleted_by)
          item.deleted_by.to_s == user_id.to_s
        elsif item.respond_to?(:created_by)
          item.created_by.to_s == user_id.to_s
        else
          false
        end
      end
    end

    def filter_by_size(items)
      size_filter = params[:size]
      return items if size_filter.blank?

      items.select do |item|
        item_size = calculate_item_memory_size(item)
        case size_filter
        when 'small'
          item_size < 1.kilobyte
        when 'medium'
          item_size >= 1.kilobyte && item_size < 100.kilobytes
        when 'large'
          item_size >= 100.kilobytes
        else
          true
        end
      end
    end

    def filter_by_date_range(items)
      date_from = parse_date_param(params[:date_from])
      date_to = parse_date_param(params[:date_to])

      return items if date_from.nil? && date_to.nil?

      items.select do |item|
        item_date = item.deleted_at
        next false unless item_date

        from_condition = date_from.nil? || item_date >= date_from
        to_condition = date_to.nil? || item_date <= date_to

        from_condition && to_condition
      end
    end

    def parse_date_param(date_string)
      return nil if date_string.blank?

      begin
        Date.parse(date_string)
      rescue
        nil
      end
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
    rescue => e
      log_error('Error finding item', e, model_type: params[:model_type], id: params[:id])
      redirect_to trash_index_path, alert: 'An error occurred while finding the item.'
    end

    def load_associations(item)
      return {} unless item.respond_to?(:class)

      associations = {}

      begin
        item.class.reflect_on_all_associations.each do |association|
          next if association.macro == :belongs_to

          related_items = safely_load_association(item, association)
          associations[association.name] = related_items if related_items.present?
        end
      rescue => e
        log_error('Error loading associations', e, item: item)
        associations = {}
      end

      associations
    end

    def safely_load_association(item, association)
      return nil unless item.respond_to?(association.name)

      related_items = item.send(association.name)
      limit_association_items(related_items)
    rescue => e
      log_debug("Skipping association #{association.name}: #{e.message}")
      nil
    end

    def limit_association_items(related_items)
      return [] if related_items.blank?
      return Array(related_items) unless related_items.respond_to?(:limit)

      begin
        if related_items.respond_to?(:first)
          related_items.is_a?(Array) ? related_items.first(10) : related_items
        else
          related_items.limit(10)
        end
      rescue => e
        log_debug("Error limiting association items: #{e.message}")
        Array(related_items).first(10)
      end
    end

    def calculate_item_memory_size(item)
      return 0 unless item.respond_to?(:attributes)

      # Simple calculation of item memory footprint
      item.attributes.to_s.bytesize
    rescue => e
      log_debug("Error calculating memory size: #{e.message}")
      0
    end

    def parse_bulk_selection
      selected_items = extract_selected_items
      return [] unless selected_items.is_a?(Array)

      parse_item_strings(selected_items)
    rescue => e
      log_error('Error parsing bulk selection', e)
      []
    end

    def extract_selected_items
      selected_items = params[:selected_items]

      return [] if selected_items.blank?

      return JSON.parse(selected_items) if selected_items.is_a?(String)

      selected_items
    rescue JSON::ParserError => e
      log_error('Invalid JSON in selected items', e)
      []
    rescue => e
      log_error('Error extracting selected items', e)
      []
    end

    def parse_item_strings(selected_items)
      return [] unless selected_items.is_a?(Array)

      parsed_items = selected_items.filter_map do |item_string|
        parse_single_item(item_string)
      end

      parsed_items.reject { |model_class, id| model_class.blank? || id.zero? }
    rescue => e
      log_error('Error parsing item strings', e)
      []
    end

    def parse_single_item(item_string)
      return nil unless item_string.is_a?(String)

      model_class, id = item_string.split(':')
      return nil if model_class.blank? || id.blank?

      [model_class, id.to_i]
    rescue => e
      log_debug("Error parsing single item '#{item_string}': #{e.message}")
      nil
    end

    # Export functionality
    def export_to_csv(items)
      csv_data = generate_csv_data(items)
      send_data csv_data,
                filename: "recycle_bin_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
                type: 'text/csv'
    end

    def export_to_json(items)
      json_data = generate_json_data(items)
      send_data json_data,
                filename: "recycle_bin_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json",
                type: 'application/json'
    end

    def generate_csv_data(items)
      require 'csv'

      CSV.generate(headers: true) do |csv|
        # Headers
        csv << ['ID', 'Model Type', 'Title', 'Deleted At', 'Size (bytes)', 'Attributes']

        # Data rows
        items.each do |item|
          csv << [
            item.id,
            item.class.name,
            item.recyclable_title,
            item.deleted_at&.strftime('%Y-%m-%d %H:%M:%S'),
            calculate_item_memory_size(item),
            item.attributes.except('deleted_at').to_json
          ]
        end
      end
    end

    def generate_json_data(items)
      data = {
        export_date: Time.current.iso8601,
        total_items: items.count,
        items: items.map do |item|
          {
            id: item.id,
            model_type: item.class.name,
            title: item.recyclable_title,
            deleted_at: item.deleted_at&.iso8601,
            size_bytes: calculate_item_memory_size(item),
            attributes: item.attributes.except('deleted_at')
          }
        end
      }

      JSON.pretty_generate(data)
    end

    def trash_index_path
      recycle_bin.root_path
    rescue StandardError
      root_path
    end

    def safe_constantize_model(model_name)
      return nil if model_name.blank?

      model_name.constantize
    rescue NameError => e
      log_warn("Failed to constantize model #{model_name}: #{e.message}")
      nil
    rescue => e
      log_error("Unexpected error constantizing model #{model_name}", e)
      nil
    end

    # Enhanced logging methods
    def log_error(message, error, context = {})
      error_context = {
        message: message,
        error: error.message,
        backtrace: error.backtrace&.first(5),
        controller: controller_name,
        action: action_name,
        params: params.except(:controller, :action, :password, :password_confirmation),
        **context
      }

      Rails.logger.error("RecycleBin Error: #{JSON.pretty_generate(error_context)}")

      # Log to external service if configured
      return unless RecycleBin.config.respond_to?(:error_logging_service)

      RecycleBin.config.error_logging_service.call(error_context)
    end

    def log_warn(message, context = {})
      warn_context = {
        message: message,
        controller: controller_name,
        action: action_name,
        **context
      }

      Rails.logger.warn("RecycleBin Warning: #{JSON.pretty_generate(warn_context)}")
    end

    def log_debug(message, context = {})
      debug_context = {
        message: message,
        controller: controller_name,
        action: action_name,
        **context
      }

      Rails.logger.debug("RecycleBin Debug: #{JSON.pretty_generate(debug_context)}")
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
end
