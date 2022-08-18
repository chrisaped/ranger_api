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

  test "update_position updates an existing position" do
    position = positions(:one)
    assert position.initial_quantity == position.current_quantity

    sell_order = order_json('sell_order')
    json_obj = JSON.parse(sell_order)

    quantity = json_obj.dig('qty').to_i
    price = json_obj.dig('price').to_d 
    side = json_obj.dig('order', 'side')

    stop_target = Target.find_by(position: position, filled: false, category: 'stop')
    assert_not stop_target.filled?
    assert stop_target.quantity == position.current_quantity
    assert stop_target.price == (position.initial_price - position.risk_per_share)

    order_attrs = {
      side: side,
      symbol: json_obj.dig('order', 'symbol'),
      raw_order: sell_order,
      quantity: quantity,
      price: price
    }
    order = Order.new(order_attrs)
    
    assert_difference -> { Position.count } => 0 do
      order.update_position(json_obj)
    end

    position = order.position
    total_quantity = json_obj.dig('position_qty').to_i
    assert position.current_quantity == total_quantity
    
    first_profit_target = find_target(quantity, price, position, true, side, 'profit')
    assert first_profit_target.filled?
    
    other_profit_targets = Target.where(position: position, filled: false, category: 'profit')
    assert other_profit_targets.count == 2

    stop_target = Target.find_by(position: position, filled: false, category: 'stop')
    assert_not stop_target.filled?
    assert stop_target.quantity == position.current_quantity
    assert stop_target.price == (price - position.risk_per_share)
  end

  test 'update_position sets stop target as filled' do
    position = positions(:one)

    stop_order = order_json('stop_order')
    json_obj = JSON.parse(stop_order)

    quantity = json_obj.dig('qty').to_i
    price = json_obj.dig('price').to_d 
    side = json_obj.dig('order', 'side')

    stop_target = Target.find_by(position: position, filled: false, category: 'stop')
    assert_not stop_target.filled?
    assert stop_target.quantity == position.current_quantity
    assert stop_target.price == (position.initial_price - position.risk_per_share)
    
    order_attrs = {
      side: side,
      symbol: json_obj.dig('order', 'symbol'),
      raw_order: stop_order,
      quantity: quantity,
      price: price
    }
    order = Order.new(order_attrs)
    
    assert_difference -> { Position.count } => 0 do
      order.update_position(json_obj)
    end

    position = order.position
    total_quantity = json_obj.dig('position_qty').to_i
    assert position.current_quantity == total_quantity
    
    all_profit_targets = Target.where(position: position, filled: false, category: 'profit')
    assert all_profit_targets.count == 3

    stop_target = Target.find_by(position: position, filled: true, category: 'stop')
    assert stop_target.filled?
  end

  def find_target(quantity, price, position, filled, side, category)
    Target.find_by(
      quantity: quantity,
      price: price,
      position: position, 
      filled: filled, 
      side: side, 
      category: category
    )
  end
  
  def order_json(name, attrs = {})
    file = File.join(Rails.root, 'test', 'data_samples', "#{name}.json")
    json = File.read(file)
    json_obj = JSON.parse(json)
    json_obj.deep_merge(attrs).to_json
  end

  def order_obj(attrs = {})
    {
      side: 'buy',
      symbol: 'TSLA',
      raw_order: order_json('new_order'),
      quantity: 31,
      price: 863.8 
    }.deep_merge(attrs)
  end
end
