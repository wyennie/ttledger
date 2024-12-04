Rails.application.routes.draw do
  get "campaigns/new"
  get "campaigns/create"
  get "campaigns/show"
  root    "static_pages#home"
  get     "/signup",  to: "users#new"
  get     "/about",   to: "static_pages#about"
  get     "/login",   to: "sessions#new"
  post    "/login",   to: "sessions#create"
  delete  "/logout",  to: "sessions#destroy"
  resources :users
  resources :campaigns
  get "up" => "rails/health#show", as: :rails_health_check
end
