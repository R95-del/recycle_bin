# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'

module RecycleBin
  module Generators
    # Generator for installing RecycleBin in a Rails application
    class InstallGenerator < ::Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)
      desc 'Install RecycleBin'

      def self.next_migration_number(path)
        next_migration_number = current_migration_number(path) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def create_migration
        print_installation_instructions
      end

      def add_route
        route "mount RecycleBin::Engine => '/trash'"
      end

      private

      def print_installation_instructions
        # For V1, we just add deleted_at to existing tables
        # Users will need to add it manually or we'll provide model generator later
        puts 'RecycleBin installed! 🗑️'
        puts ''
        puts 'Next steps:'
        puts '1. Add deleted_at column to your models:'
        puts '   rails generate migration AddDeletedAtToUsers deleted_at:datetime'
        puts ''
        puts '2. Include the module in your models:'
        puts '   class User < ApplicationRecord'
        puts '     include RecycleBin::SoftDeletable'
        puts '   end'
        puts ''
        puts '3. Visit /trash to see the web interface'
      end
    end
  end
end
