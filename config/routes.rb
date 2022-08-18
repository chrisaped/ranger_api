Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  post '/fetch_positions', to: 'orders#fetch_positions'
  post '/create_position', to: 'positions#create'
end
