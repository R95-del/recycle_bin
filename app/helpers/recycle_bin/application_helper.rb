# frozen_string_literal: true

module RecycleBin
  module ApplicationHelper
    def recyclable_icon(item)
      case item.class.name.downcase
      when /user/
        "👤"
      when /post|article|blog/
        "📝"
      when /comment/
        "💬"
      when /image|photo/
        "🖼️"
      when /file|document/
        "📄"
      else
        "📋"
      end
    end

    def delete_confirmation_message(item)
      "Are you sure you want to permanently delete this #{item.class.name.downcase}? This action cannot be undone!"
    end

    def restore_confirmation_message(item)
      "Are you sure you want to restore this #{item.class.name.downcase}?"
    end

    def time_ago_with_tooltip(time)
      content_tag :span, time_ago_in_words(time) + " ago",
                  title: time.strftime('%B %d, %Y at %I:%M %p'),
                  data: { toggle: 'tooltip' }
    end
  end
end
