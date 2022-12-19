constraints subdomain: 'api', format: :json do
  namespace :api, defaults: { format: :json }, path: nil do
    namespace :v1 do
      devise_for :users, singular: :user, controllers: { 
        registrations: "api/v1/users/registrations",
        sessions: "api/v1/users/sessions"
      }

      resource :csrf, only: [:restore] do
        get 'restore', to: 'csrf#restore'
      end

      resources :users do 
        collection do 
          get '/test', to: 'users#test'
          post '/authenticated_endpoint', to: 'users#authenticated_endpoint'
        end
      end
    end
  end
end