class PositionsController < ApplicationController
  def create
    position = create_position(params)
    render status: 201
  end

  def get_positions
    positions = Position.generate_states
    render json: positions
  end

  private

  def create_position(params)
    quantity = params.dig('qty').to_i

    Position.create!(
      initial_quantity: quantity,
      symbol: params.dig('symbol'),
      side: determine_position_side(params.dig('side')),
      current_quantity: quantity,
      initial_price: params.dig('limit_price').to_d,
      initial_stop_price: params.dig('stop_price').to_d
    )    
  end

  def determine_position_side(order_side)
    order_side == 'buy' ? 'long' : 'short'
  end
end


