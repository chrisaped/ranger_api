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
    
    assert_difference -> { Position.count } => 1 do
      order.create_or_update_position(risk_per_share)
    end

    assert_not order.position.nil?
  end

  def new_order_json
    file = File.join(Rails.root, 'test', 'data_samples', 'new_order.json')
    File.read(file)
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
