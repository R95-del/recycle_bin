# frozen_string_literal: true

require 'rails/generators'

module RecycleBin
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      desc 'Install RecycleBin in your Rails application'

      def create_initializer
        create_file 'config/initializers/recycle_bin.rb', <<~RUBY
          # RecycleBin Configuration
          RecycleBin.configure do |config|
            # Enable web interface (default: true)
            config.enable_web_interface = true

            # Items per page in web interface (default: 25)
            # config.items_per_page = 25

            # Auto-cleanup items after specified time (default: nil - disabled)
            # config.auto_cleanup_after = 30.days

            # Method to get current user for audit trail#{'  '}
            # config.current_user_method = :current_user

            # Authorization callback - uncomment to restrict access
            # config.authorize_with do |controller|
            #   # Example: Only allow admins
            #   controller.current_user&.admin?
            # end
          end
        RUBY
      end

      def add_route
        route "mount RecycleBin::Engine => '/recycle_bin'"
      end

      def print_installation_instructions
        display_success_header
        display_next_steps
        display_configuration_info
        display_success_footer
      end

      private

      def display_success_header
        say "\n#{'=' * 60}", :green
        say '🗑️  RecycleBin installed successfully!', :green
        say '=' * 60, :green
        say ''
      end

      def display_next_steps
        say 'Next steps:', :yellow
        say '1. Add deleted_at column to your models:'
        say '   rails generate migration AddDeletedAtToUsers deleted_at:datetime:index'
        say ''
        say '2. Include the module in your models:'
        say '   class User < ApplicationRecord'
        say '     include RecycleBin::SoftDeletable'
        say '   end'
        say ''
        say '3. Run migrations:'
        say '   rails db:migrate'
        say ''
        say '4. Visit /recycle_bin to see the web interface'
        say ''
      end

      def display_configuration_info
        say 'Configuration file created at:'
        say '   config/initializers/recycle_bin.rb'
      end

      def display_success_footer
        say '=' * 60, :green
      end
    end
  end
end
