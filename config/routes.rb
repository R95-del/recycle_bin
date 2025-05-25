# frozen_string_literal: true

# RecycleBin Engine Routes Configuration
# These routes are mounted under the main application's routes
# Example: mount RecycleBin::Engine, at: '/recycle_bin'

RecycleBin::Engine.routes.draw do
  # Root route - defaults to listing all trashed items
  root 'trash#index'

  # Main trash routes
  get 'trash', to: 'trash#index', as: :trash_index
  get 'trash/:model_type/:id', to: 'trash#show', as: :trash_item

  # Individual item operations
  patch 'trash/:model_type/:id/restore', to: 'trash#restore', as: :restore_trash_item
  delete 'trash/:model_type/:id', to: 'trash#destroy', as: :destroy_trash_item

  # Bulk operations
  patch 'trash/bulk_restore', to: 'trash#bulk_restore', as: :bulk_restore_trash
  delete 'trash/bulk_destroy', to: 'trash#bulk_destroy', as: :bulk_destroy_trash

  # Model-specific trash listing (optional)
  get 'trash/:model_type', to: 'trash#index', as: :model_trash_index
end

# Instructions for main Rails application:
# Add this line to your main app's config/routes.rb file:
# mount RecycleBin::Engine, at: '/recycle_bin'
#
# This will make the following URLs available:
# GET    /recycle_bin                                    # List all trashed items
# GET    /recycle_bin/trash                              # Same as above
# GET    /recycle_bin/trash/:model_type                  # List trashed items of specific model
# GET    /recycle_bin/trash/:model_type/:id              # Show specific trashed item
# PATCH  /recycle_bin/trash/:model_type/:id/restore      # Restore specific item
# DELETE /recycle_bin/trash/:model_type/:id              # Permanently delete item
# PATCH  /recycle_bin/trash/bulk_restore                 # Restore multiple items
# DELETE /recycle_bin/trash/bulk_destroy                 # Permanently delete multiple items
