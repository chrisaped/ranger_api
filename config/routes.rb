Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  post '/create_position', to: 'positions#create'
  put '/cancel_position', to: 'positions#cancel'
  post '/create_order', to: 'orders#create'
  get '/open_positions', to: 'positions#open_positions'
  get '/pending_positions', to: 'positions#pending_positions'
  get '/closed_positions', to: 'positions#closed_positions'
  get '/total_profit_or_loss_today', to: 'positions#total_profit_or_loss_today'
end
