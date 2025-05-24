RecycleBin::Engine.routes.draw do
  root 'trash#index'
  
  resources :trash, only: [:index, :show, :destroy] do
    member do
      patch :restore
      delete :permanent_delete, action: :destroy
    end
    
    collection do
      patch :bulk_restore
      delete :bulk_destroy
    end
  end
  
  # Alternative route structure for RESTful access with model type
  get '/trash/:model_type', to: 'trash#index', as: :model_trash
  get '/trash/:model_type/:id', to: 'trash#show', as: :trash_item
  patch '/trash/:model_type/:id/restore', to: 'trash#restore', as: :restore_trash_item
  delete '/trash/:model_type/:id', to: 'trash#destroy', as: :destroy_trash_item
end
