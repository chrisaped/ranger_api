class PositionsController < ApplicationController
  def create
    create_position(params)
    render status: 201
  end

  def cancel
    symbol = params.dig(:symbol)
    position = Position.find_by(symbol: symbol, status: :pending)
    status = 200

    if position
      position.canceled!
    else
      puts "no open position found for #{symbol}"
      status = 400
    end

    render status: status
  end

  def open_positions
    positions = Position.open.order(:created_at).map(&:create_state)
    render json: positions
  end
  
  def pending_positions
    positions = Position.pending.order(:created_at).map(&:create_state)
    render json: positions
  end

  def closed_positions
    positions = Position.closed.order(created_at: :desc).map(&:create_state)
    render json: positions
  end

  def total_profit_or_loss_today
    total_profit_or_loss_today = Position.total_profit_or_loss_today
    render json: total_profit_or_loss_today
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


