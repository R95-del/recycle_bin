# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'

module RecycleBin
  module Generators
    class AddDeletedAtGenerator < ::Rails::Generators::NamedBase
      include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)
      desc 'Add deleted_at column to a model for soft delete functionality'

      def self.next_migration_number(path)
        next_migration_number = current_migration_number(path) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def create_migration
        migration_template 'add_deleted_at_migration.rb.erb', 
                          "db/migrate/add_deleted_at_to_#{table_name}.rb"
      end

      def show_instructions
        say ""
        say "Next steps:", :green
        say "1. Run the migration: rails db:migrate"
        say "2. Include RecycleBin::SoftDeletable in your #{class_name} model:"
        say ""
        say "   class #{class_name} < ApplicationRecord", :yellow
        say "     include RecycleBin::SoftDeletable", :yellow
        say "   end", :yellow
        say ""
        say "3. Your #{class_name.downcase} records will now be soft deleted when you call .destroy"
        say "4. Visit /recycle_bin to manage deleted items"
      end

      private

      def table_name
        @table_name ||= name.tableize
      end

      def class_name
        @class_name ||= name.classify
      end
    end
  end
end