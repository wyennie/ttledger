
Rails.application.routes.draw do
  root    "static_pages#home"
  get     "/signup",  to: "users#new"
  get     "/about",   to: "static_pages#about"
  get     "/login",   to: "sessions#new"
  post    "/login",   to: "sessions#create"
  delete  "/logout",  to: "sessions#destroy"
  get "confirm_email", to: "users#confirm_email", as: "confirm_email"
  resources :users
  resources :friendships, only: [ :create, :update ]
  resources :campaigns do
    resources :pages, param: :slug
    resources :characters, only: [ :create, :edit, :update, :destroy ] do
      resources :items, only: [ :create, :edit, :update, :destroy ]
    end
    member do
      post :invite_user
      post :accept_invitation
      get  :manage
    end
  end
  resources :chats, only: %i[create show] do
    resources :messages, only: %i[create] do
      collection do
        delete :destroy_all
      end
    end
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
