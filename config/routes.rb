Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :product_imports do

      resources :product_import_items
      resources :product_import_image_locations

      # post :import, on: :member
      # TODO implement export functionality
      # post :export, on: :member
    end

    resources :product_import_image_servers
  end
  get 'admin/product_imports/:id/import' => 'admin/product_imports#import'
end
