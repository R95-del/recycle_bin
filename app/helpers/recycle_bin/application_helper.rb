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
  end
end
