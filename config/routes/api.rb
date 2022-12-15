constraints subdomain: 'api', format: :json do
  namespace :api, defaults: { format: :json }, path: nil do
    namespace :v1 do
      resources :users do 
        collection do 
          get '/test', to: 'users#test'
        end
      end
    end
  end
end