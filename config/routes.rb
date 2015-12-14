Spree::Core::Engine.routes.draw do


  Spree::Core::Engine.routes.draw do
    namespace :admin do
      resources :product_imports do
        post :import, on: :member
      end
    end
  end

end
