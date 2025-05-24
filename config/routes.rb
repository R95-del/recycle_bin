# frozen_string_literal: true

RecycleBin::Engine.routes.draw do
  get 'recycle_bin' => 'recycle_bin#index'
end
