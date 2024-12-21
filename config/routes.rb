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
    resources :characters, only: [ :create, :edit, :update, :destroy ] do
      resources :items, only: [ :create, :edit, :update, :destroy ]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
