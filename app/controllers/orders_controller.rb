class OrdersController < ApplicationController
  def create    
    order_status = params.dig('order', 'status')

    if order_status == 'filled'
      order = Order.new(order_params(params))
      order.update_position(params)
      order.save!
    end

    render status: 201
  end

  private

  def order_params(params)
    {
      side: params.dig('order', 'side'),
      symbol: params.dig('order', 'symbol'),
      raw_order: params,
      quantity: params.dig('qty').to_i,
      price: params.dig('order', 'limit_price').to_d,
      filled_avg_price: params.dig('order', 'filled_avg_price').to_d
    }
  end
end
