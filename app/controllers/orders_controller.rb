class OrdersController < ApplicationController
  def process
    puts "here are the process params:"
    p params

    risk_per_share = params.dig('risk_per_share')
    order_json = params.dig('order')
    
    json_obj = JSON.parse(order_json)        
    order_status = json_obj.dig('order', 'status')

    order =  { error: "no order" }

    if order_status == 'filled'
      # create order
      order = Order.new(order_params(json_obj, order_json))
      order.create_or_update_position(risk_per_share, json_obj)
      order.save!
    end

    render json: order
  end

  private

  def order_params(json_obj, order_json)
    {
      side: json_obj.dig('order', 'side'),
      symbol: json_obj.dig('order', 'symbol'),
      raw_order: order_json,
      quantity: json_obj.dig('qty').to_i,
      price: json_obj.dig('price').to_d 
    }
  end
end
