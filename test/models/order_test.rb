require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "can create a new order" do
    new_attrs = { status: :pending }
    position = Position.create!(position_obj(new_attrs))
    assert position.pending?
    
    new_attrs = {
      "order" => {
        "symbol" => "AMC"
      }
    }
    new_order_params = order_json('new_order', new_attrs)
    order = Order.new(order_params(new_order_params))
    order.position = position

    assert_difference -> { Order.count } => 1 do
      order.save!
    end
  end

  test "can not create a duplicate order" do
    new_attrs = { status: :pending }
    position = Position.create!(position_obj(new_attrs))
    assert position.pending?
    
    new_attrs = {
      "order" => {
        "symbol" => "AMC"
      }
    }
    new_order_params = order_json('new_order', new_attrs)
    order = Order.new(order_params(new_order_params))
    order.position = position

    assert_difference -> { Order.count } => 1 do
      order.save!
    end

    order = Order.new(order_params(new_order_params))
    order.position = position

    assert_raise(Exception) do
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

  test "update_position sets a pending position to open" do
    new_attrs = { status: :pending }
    position = Position.create!(position_obj(new_attrs))
    assert position.pending?
    
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

    quantity = sell_order.dig('order', 'filled_qty').to_i
    price = sell_order.dig('order', 'limit_price').to_d 
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
      price: price,
      filled_avg_price: sell_order.dig('order', 'filled_avg_price').to_d,
      alpaca_order_id: sell_order.dig('order', 'id')
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
    assert stop_target.price == position.initial_filled_avg_price
  end

  test 'update_position sets stop target as filled' do
    position = positions(:one)
    assert position.open?

    stop_order = order_json('market_sell_stop_order')

    quantity = stop_order.dig('order', 'filled_qty').to_i
    price = stop_order.dig('order', 'limit_price').to_d 
    side = stop_order.dig('order', 'side')

    stop_target = Target.find_by(position: position, filled: false, category: 'stop')
    assert_not stop_target.filled?
    assert stop_target.quantity == position.current_quantity
    assert stop_target.price == (position.initial_price - position.risk_per_share)
    assert stop_target.filled_avg_price.nil?
    
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
    assert position.closed?
    assert position.no_target_sell_filled_avg_price.nil?
    assert position.no_target_sell_filled_qty.nil?
    
    all_profit_targets = Target.where(position: position, filled: false, category: 'profit')
    assert all_profit_targets.count == 3

    stop_target = Target.find_by(position: position, filled: true, category: 'stop')
    assert stop_target.filled?
    assert stop_target.filled_avg_price == order.filled_avg_price
  end

  test 'update_position sets no_target_sell columns' do
    new_attrs = { 
      symbol: 'CHS',
      initial_filled_avg_price: 30.0,
      risk_per_share: 0.50
    }
    position = Position.create!(position_obj(new_attrs))
    
    position.create_targets
    assert position.targets.length > 0

    assert position.no_target_sell_filled_avg_price.nil?
    assert position.no_target_sell_filled_qty.nil?

    sell_order_attributes = { 
      "order" => { 
        "filled_qty" => "600", 
        "qty" => "600", 
        "symbol" => "CHS" 
      },
      "position_qty" => "0",
      "qty" => "600"
    }
    sell_order = order_json('sell_order', sell_order_attributes)

    quantity = sell_order.dig('qty').to_i
    price = sell_order.dig('price').to_d 
    side = sell_order.dig('order', 'side')
    
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
    assert position.closed?
    assert position.no_target_sell_filled_avg_price == order.filled_avg_price
    assert position.no_target_sell_filled_qty == order.quantity
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
      price: params.dig('order', 'limit_price').to_d,
      filled_avg_price: params.dig('order', 'filled_avg_price').to_d,
      alpaca_order_id: params.dig('order', 'id')
    }
  end
end
