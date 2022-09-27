class OrdersController < ApplicationController
  def create    
    order_status = params.dig('order', 'status')

    alpaca_order_id = params.dig('order', 'id')
    existing_order = Order.find_by(alpaca_order_id: alpaca_order_id)
    
    status = 400

    if order_status == 'filled' && existing_order.nil?
      order = Order.new(order_params(params))
      order.update_position(params)
      order.save!

      status = 201
    end

    render status: status
  end

  private

  def order_params(params)
    {
      side: params.dig('order', 'side'),
      symbol: params.dig('order', 'symbol'),
      raw_order: params,
      quantity: params.dig('order', 'filled_qty').to_i,
      price: params.dig('order', 'limit_price').to_d,
      filled_avg_price: params.dig('order', 'filled_avg_price').to_d,
      alpaca_order_id: params.dig('order', 'id')
    }
  end
end
