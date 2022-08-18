class PositionsController < ApplicationController
  def create
    puts "here are the params:"
    p params

    position_json = params.dig('position')
    position_obj = JSON.parse(position_json)

    create_position(position_obj)
  end

  private

  def create_position(position_obj)
    Position.create!(
      initial_quantity: position_obj.dig('qty'),
      symbol: position_obj.dig('symbol'),
      side: determine_position_side(position_obj.dig('side')),
      current_quantity: position_obj.dig('qty'),
      initial_price: position_obj.dig('limitPrice'),
      risk_per_share: calculate_risk_per_share(
        position_obj.dig('limitPrice'),
        position_obj.dig('stopPrice')
      )
    )    
  end

  def determine_position_side(order_side)
    order_side == 'buy' ? 'long' : 'short'
  end

  def calculate_risk_per_share(initial_price, stop_price)
    (initial_price.to_d - stop_price.to_d).abs
  end
end


