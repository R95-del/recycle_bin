# frozen_string_literal: true

RecycleBin::Engine.routes.draw do
  root 'trash#index'

  # Standard resource routes
  resources :trash, only: [:index] do
    collection do
      patch :bulk_restore
      delete :bulk_destroy
      delete :cleanup_large_items
    end
  end

  # Custom routes for individual items with model type
  get 'trash/:model_type/:id', to: 'trash#show', as: 'trash'
  patch 'trash/:model_type/:id/restore', to: 'trash#restore', as: 'restore_trash'
  delete 'trash/:model_type/:id', to: 'trash#destroy', as: 'destroy_trash'
end
