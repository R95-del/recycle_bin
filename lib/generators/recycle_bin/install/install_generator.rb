# frozen_string_literal: true

require 'rails/generators'

module RecycleBin
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      desc 'Install RecycleBin in your Rails application'

      def create_initializer
        template 'recycle_bin.rb', 'config/initializers/recycle_bin.rb'
      end

      def add_route
        route "mount RecycleBin::Engine => '/recycle_bin'"
      end

      def print_installation_instructions
        say "\n" + "="*60
        say "🗑️  RecycleBin installed successfully!"
        say "="*60
        say ""
        say "Next steps:"
        say "1. Add deleted_at column to your models:"
        say "   rails generate migration AddDeletedAtToUsers deleted_at:datetime"
        say ""
        say "2. Include the module in your models:"
        say "   class User < ApplicationRecord"
        say "     include RecycleBin::SoftDeletable"
        say "   end"
        say ""
        say "3. Visit /recycle_bin to see the web interface"
        say ""
        say "Configuration file created at:"
        say "   config/initializers/recycle_bin.rb"
        say "="*60
      end
    end
  end
end