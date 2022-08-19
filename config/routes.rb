Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  post '/create_position', to: 'positions#create'
  post '/create_order', to: 'orders#create'
  get '/get_positions', to: 'positions#get_positions'
end
