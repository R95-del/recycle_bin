# frozen_string_literal: true

module RecycleBin
  # Helper methods for RecycleBin views
  module ApplicationHelper
    def recyclable_icon(item)
      icon_class = case item.class.name.downcase
                   when 'user'
                     'fa-user'
                   when 'post', 'article'
                     'fa-file-text'
                   when 'comment'
                     'fa-comment'
                   else
                     'fa-trash'
                   end

      content_tag(:i, '', class: "fa #{icon_class}")
    end

    def time_ago_in_words_or_date(time)
      return 'Never' if time.blank?

      if time > 1.week.ago
        "#{time_ago_in_words(time)} ago"
      else
        time.strftime('%B %d, %Y')
      end
    end

    # Check if any filters are currently active
    def any_filters_active?
      %w[search type time deleted_by size date_from date_to].any? { |param| params[param].present? }
    end

    # Generate human-readable label for time filter
    def time_filter_label(time_value)
      case time_value
      when 'today'
        'Today'
      when 'week'
        'This Week'
      when 'month'
        'This Month'
      when 'year'
        'This Year'
      else
        time_value.to_s.humanize
      end
    end

    # Generate human-readable label for size filter
    def size_filter_label(size_value)
      case size_value
      when 'small'
        'Small (< 1KB)'
      when 'medium'
        'Medium (1KB - 100KB)'
      when 'large'
        'Large (> 100KB)'
      else
        size_value.to_s.humanize
      end
    end

    # Classify item size for CSS styling
    def size_class(item)
      size_bytes = calculate_item_memory_size(item)

      if size_bytes < 1.kilobyte
        'small'
      elsif size_bytes < 100.kilobytes
        'medium'
      else
        'large'
      end
    end

    # Calculate item memory size (helper method for views)
    def calculate_item_memory_size(item)
      return 0 unless item.respond_to?(:attributes)

      # Simple calculation of item memory footprint
      item.attributes.to_s.bytesize
    rescue StandardError => e
      Rails.logger.debug("Error calculating memory size: #{e.message}")
      0
    end

    # Format file size in human-readable format
    def human_file_size(bytes)
      return '0 B' if bytes.nil? || bytes.zero?

      units = %w[B KB MB GB TB]
      size = bytes.to_f
      unit_index = 0

      while size >= 1024 && unit_index < units.length - 1
        size /= 1024
        unit_index += 1
      end

      "#{size.round(2)} #{units[unit_index]}"
    end

    # Highlight search terms in text
    def highlight_search_terms(text, search_term)
      return text if search_term.blank? || text.blank?

      text.to_s.gsub(/(#{Regexp.escape(search_term)})/i, '<mark>\1</mark>').html_safe
    end

    # Generate search result summary
    def search_result_summary(total_count, search_term)
      if search_term.present?
        "Found #{total_count} result#{total_count == 1 ? '' : 's'} for \"#{search_term}\""
      else
        "#{total_count} item#{total_count == 1 ? '' : 's'} in trash"
      end
    end

    # Check if current page has search results
    def has_search_results?
      @deleted_items&.any?
    end

    # Generate export filename with current filters
    def export_filename_with_filters(base_name, format)
      filters = []
      filters << "search_#{params[:search]}" if params[:search].present?
      filters << "type_#{params[:type]}" if params[:type].present?
      filters << "time_#{params[:time]}" if params[:time].present?
      filters << "user_#{params[:deleted_by]}" if params[:deleted_by].present?
      filters << "size_#{params[:size]}" if params[:size].present?

      if params[:date_from].present? || params[:date_to].present?
        date_range = [params[:date_from], params[:date_to]].compact.join('_to_')
        filters << "date_#{date_range}" if date_range.present?
      end

      timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
      filter_suffix = filters.any? ? "_#{filters.join('_')}" : ''

      "#{base_name}#{filter_suffix}_#{timestamp}.#{format}"
    end

    # Generate filter breadcrumb
    def filter_breadcrumb
      return unless any_filters_active?

      breadcrumbs = []

      breadcrumbs << "Search: \"#{params[:search]}\"" if params[:search].present?

      breadcrumbs << "Type: #{params[:type]}" if params[:type].present?

      breadcrumbs << "Time: #{time_filter_label(params[:time])}" if params[:time].present?

      breadcrumbs << "User: #{params[:deleted_by]}" if params[:deleted_by].present?

      breadcrumbs << "Size: #{size_filter_label(params[:size])}" if params[:size].present?

      if params[:date_from].present? || params[:date_to].present?
        date_range = [params[:date_from], params[:date_to]].compact.join(' to ')
        breadcrumbs << "Date: #{date_range}"
      end

      breadcrumbs.join(' • ')
    end

    # Check if advanced filters are visible
    def advanced_filters_visible?
      %w[deleted_by size date_from date_to].any? { |param| params[param].present? }
    end

    # Generate filter count badge
    def active_filter_count
      count = 0
      count += 1 if params[:search].present?
      count += 1 if params[:type].present?
      count += 1 if params[:time].present?
      count += 1 if params[:deleted_by].present?
      count += 1 if params[:size].present?
      count += 1 if params[:date_from].present? || params[:date_to].present?
      count
    end

    # Check if item matches current search
    def item_matches_search?(item, search_term)
      return true if search_term.blank?

      search_term = search_term.downcase

      # Check common fields
      %w[title name email content body description].any? do |field|
        item.send(field).to_s.downcase.include?(search_term) if item.respond_to?(field) && item.send(field).present?
      end ||
        # Check ID
        item.id.to_s.include?(search_term) ||
        # Check model class name
        item.class.name.downcase.include?(search_term) ||
        # Check all attributes
        item.attributes.values.any? { |val| val.to_s.downcase.include?(search_term) }
    end
  end
end
