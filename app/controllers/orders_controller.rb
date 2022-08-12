class OrdersController < ApplicationController
  def process
    puts "here are the process params:"
    p params

    risk_per_share = params.dig('risk_per_share')
    order_json = params.dig('order')
    
    json_obj = JSON.parse(order_json)
    order_obj = json_obj.dig('order')
    
    @event = json_obj.dig('event')
    
    
    if @event == 'fill'
      # the fill event conditional should go in the server.js
      # create order
      order = Order.new(order_params(order_obj, order_json))
      order.create_or_update_position(risk_per_share)
      order.save!
    end

    render json: order
  end

  private

  def order_params(order_obj, order_json)
    {
      side: order_obj.dig('side'),
      symbol: order_obj.dig('symbol'),
      raw_order: order_json,
      quantity: order_obj.dig('filled_qty').to_i,
      price: order_obj.dig('filled_avg_price').to_d 
    }
  end
end
