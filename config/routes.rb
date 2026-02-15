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
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
