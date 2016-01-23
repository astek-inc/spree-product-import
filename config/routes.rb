Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :product_imports do
      # post :import, on: :member
      # TODO implement export functionality
      # post :export, on: :member
    end
  end
  get 'admin/product_imports/:id/import' => 'admin/product_imports#import'
end
