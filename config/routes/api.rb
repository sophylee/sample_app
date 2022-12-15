constraints subdomain: 'api', format: :json do
  namespace :api, defaults: { format: :json }, path: nil do
    namespace :v1 do
      devise_for :users, singular: :user, controllers: { registrations: "api/v1/users/registrations" }

      resources :users do 
        collection do 
          get '/test', to: 'users#test'
        end
      end
    end
  end
end