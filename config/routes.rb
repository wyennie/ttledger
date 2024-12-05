Rails.application.routes.draw do
  root    "static_pages#home"
  get     "/signup",  to: "users#new"
  get     "/about",   to: "static_pages#about"
  get     "/login",   to: "sessions#new"
  post    "/login",   to: "sessions#create"
  delete  "/logout",  to: "sessions#destroy"
  resources :users
  resources :campaigns do
    resources :characters, only: [:new, :create, :edit, :update, :destroy]
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
