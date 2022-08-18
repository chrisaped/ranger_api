class OrdersController < ApplicationController
  def fetch_position_state
    puts "here are the params:"
    p params

    risk_per_share = params.dig('risk_per_share')
    order_json = params.dig('order')
    
    json_obj = JSON.parse(order_json)        
    order_status = json_obj.dig('order', 'status')

    position_state = {}.to_json

    if order_status == 'filled'
      order = Order.new(order_params(json_obj, order_json))
      order.create_or_update_position(risk_per_share, json_obj)
      order.save!

      position_state = create_position_state(order.position)
    end

    render json: position_state
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

  def create_position_state(position)
    position_state_obj = {
      position: position,
      profit_targets: {},
      stop_target: {}
    }
    
    profit_targets = Target.where(position: position, category: 'profit').order(:created_at)
    profit_targets.each do |profit_target|
      position_state_obj[:profit_targets][profit_target.multiplier.to_sym] = profit_target
    end
    
    stop_target = Target.find_by(position: position, category: 'stop')
    position_state_obj[:stop_target] = stop_target

    position_state_obj.to_json
  end
end
