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

  test "update_position raises an error if there is no position" do
    order = Order.new(order_obj)

    sell_order = order_json('sell_order')

    assert_raise(Exception) do
      order.update_position(sell_order)
    end
  end

  test "update_position updates position and creates targets for a new order" do
    position = Position.create!(position_obj)
    assert position.open?
    initial_quantity = position.initial_quantity
    assert position.current_quantity == initial_quantity
    assert position.initial_filled_avg_price.nil?
    assert position.risk_per_share.nil?
    assert position.targets.empty?

    new_attrs = {
      "order" => {
        "symbol" => "AMC"
      }
    }
    new_order_params = order_json('new_order', new_attrs)
    order = Order.new(order_params(new_order_params))
    order.update_position(new_order_params)
    position = order.position

    assert position.open?
    assert position.current_quantity == initial_quantity
    assert_not position.initial_filled_avg_price.nil?
    assert_not position.risk_per_share.nil?
    assert position.targets.length == 4
  end

  test "update_position updates an existing position" do
    position = positions(:one)
    assert position.initial_quantity == position.current_quantity

    sell_order = order_json('sell_order')

    quantity = sell_order.dig('qty').to_i
    price = sell_order.dig('price').to_d 
    side = sell_order.dig('order', 'side')

    stop_target = Target.find_by(position: position, filled: false, category: 'stop')
    assert_not stop_target.filled?
    assert stop_target.quantity == position.current_quantity
    assert stop_target.price == (position.initial_price - position.risk_per_share)

    order_attrs = {
      side: side,
      symbol: sell_order.dig('order', 'symbol'),
      raw_order: sell_order,
      quantity: quantity,
      price: price
    }
    order = Order.new(order_attrs)
    
    assert_difference -> { Position.count } => 0 do
      order.update_position(sell_order)
    end

    position = order.position
    total_quantity = sell_order.dig('position_qty').to_i
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

    quantity = stop_order.dig('qty').to_i
    price = stop_order.dig('price').to_d 
    side = stop_order.dig('order', 'side')

    stop_target = Target.find_by(position: position, filled: false, category: 'stop')
    assert_not stop_target.filled?
    assert stop_target.quantity == position.current_quantity
    assert stop_target.price == (position.initial_price - position.risk_per_share)
    
    order_attrs = {
      side: side,
      symbol: stop_order.dig('order', 'symbol'),
      raw_order: stop_order,
      quantity: quantity,
      price: price
    }
    order = Order.new(order_attrs)
    
    assert_difference -> { Position.count } => 0 do
      order.update_position(stop_order)
    end

    position = order.position
    total_quantity = stop_order.dig('position_qty').to_i
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
    json_obj.deep_merge(attrs)
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

  def position_obj(attrs = {})
    {
      status: :open,
      initial_quantity: 600,
      symbol: 'AMC',
      side: :long,
      current_quantity: 600,
      initial_price: 30.0,
      initial_stop_price: 29.50
    }.deep_merge(attrs)
  end

  def order_params(params)
    {
      side: params.dig('order', 'side'),
      symbol: params.dig('order', 'symbol'),
      raw_order: params,
      quantity: params.dig('qty').to_i,
      price: params.dig('price').to_d,
      filled_avg_price: params.dig('order', 'filled_avg_price').to_d
    }
  end
end
