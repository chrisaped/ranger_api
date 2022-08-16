require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "can create a new order" do
    position = positions(:one)
    
    order = Order.new(order_obj)
    order.position = position

    assert_difference -> { Order.count } => 1 do
      order.save!
    end
  end

  test "create_or_update_position creates a new position" do
    order = Order.new(order_obj)
    risk_per_share = 0.50
    json_obj = JSON.parse(new_order_json)
    
    assert_difference -> { Position.count } => 1 do
      order.create_or_update_position(risk_per_share, json_obj)
    end

    assert_not order.position.nil?
  end

  def new_order_json(attrs = {})
    file = File.join(Rails.root, 'test', 'data_samples', 'new_order.json')
    json = File.read(file)
    json_obj = JSON.parse(json)
    json_obj.deep_merge(attrs).to_json
  end

  def order_obj(attrs = {})
    {
      side: 'buy',
      symbol: 'TSLA',
      raw_order: new_order_json,
      quantity: 31,
      price: 863.8 
    }.deep_merge(attrs)
  end
end
