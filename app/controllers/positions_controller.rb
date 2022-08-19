class PositionsController < ApplicationController
  def create
    position = create_position(params)

    render json: position
  end

  private

  def create_position(params)
    Position.create!(
      initial_quantity: params.dig('qty').to_i,
      symbol: params.dig('symbol'),
      side: determine_position_side(params.dig('side')),
      current_quantity: params.dig('qty').to_i,
      initial_price: params.dig('limit_price').to_d,
      risk_per_share: calculate_risk_per_share(
        params.dig('limit_price').to_d,
        params.dig('stop_price').to_d
      )
    )    
  end

  def determine_position_side(order_side)
    order_side == 'buy' ? 'long' : 'short'
  end

  def calculate_risk_per_share(initial_price, stop_price)
    (initial_price - stop_price).abs
  end
end


