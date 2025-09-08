# frozen_string_literal: true

RecycleBin::Engine.routes.draw do
  # Dashboard as root
  root 'trash#dashboard'

  # Dashboard route
  get 'dashboard', to: 'trash#dashboard', as: 'dashboard'

  # Standard resource routes with format support
  resources :trash, only: [:index] do
    collection do
      patch :bulk_restore
      delete :bulk_destroy
      delete :cleanup_large_items
      # Export routes
      get :export_csv, defaults: { format: :csv }
      get :export_json, defaults: { format: :json }
    end
  end

  # Custom routes for individual items with model type
  get 'trash/:model_type/:id', to: 'trash#show', as: 'trash'
  patch 'trash/:model_type/:id/restore', to: 'trash#restore', as: 'restore_trash'
  delete 'trash/:model_type/:id', to: 'trash#destroy', as: 'destroy_trash'
end
