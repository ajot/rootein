Rails.application.routes.draw do
  resource :session
  resource :registration, only: [:new, :create]
  resources :passwords, param: :token
  get "welcome", to: "landing#show", as: :landing
  get "about", to: "about#show", as: :about
  root "dashboard#show"
  resource :account, only: [:show, :update], controller: "account"
  resources :rooteins do
    collection do
      patch :reorder
    end
    resources :completions, only: [:create, :destroy]
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
