Rails.application.routes.draw do
  namespace :api do
    post "auth/register", to: "auth#register"
    post "auth/login", to: "auth#login"

    resources :businesses, only: [:index, :show, :create] do
      resources :services, only: [:index, :create, :update, :destroy]
      resources :appointments, only: [:index]
      resource :hours, only: [:show, :update], controller: "business_hours"
      get "members", to: "business_members#index"
      post "members", to: "business_members#create"
    end

    post "appointments/:appointment_id/cancel", to: "appointment_cancellations#create"

    namespace :public do
      get "businesses/:slug", to: "businesses#show"
      get "businesses/:slug/availability", to: "availability#index"
      post "businesses/:slug/appointments", to: "appointments#create"
    end
  end
end
