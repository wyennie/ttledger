Rails.application.routes.draw do
  root "static_pages#home"
  get "/signup", to: "users#new"
  get "/about",  to: "static_pages#about"
  get "up" => "rails/health#show", as: :rails_health_check
  resources :users
end
