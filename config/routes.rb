Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :product_imports do

      resources :product_import_items
      resources :product_import_image_locations do
        collection do
          post :update_positions
        end
      end

      member do
        get 'import'
        get 'delete_import'
      end

    end

    resources :product_import_image_servers
  end
end
