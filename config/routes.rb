Rails.application.routes.draw do
  resources :organizations, only: %i[index show new create edit update destroy] do
    member do
      get :analytics
      get :members
    end

    resources :participation_rules, except: [:show] do
      collection do
        get :test
      end
    end
  end

    resources :parental_consents, only: [:new, :create] do
    member do
      get :show
      patch :grant
      patch :deny
    end
  end



  devise_for :users, controllers: { registrations: 'users/registrations' }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "organizations#index"
end
