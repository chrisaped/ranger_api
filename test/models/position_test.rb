require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "can create a position" do
    assert_difference -> { Position.count } => 1 do
      Position.create!(position_obj)
    end
  end

  test "create_targets works" do 
    assert_difference -> { Position.count } => 1, -> { Target.count } => 4 do
      position = Position.create!(position_obj)
      position.create_targets
    end    
  end

  test "create_targets creates 4 targets with the correct categories" do
    position = Position.create!(position_obj)
    position.create_targets

    first_target = position.targets[0]
    second_target = position.targets[1]
    third_target = position.targets[2]
    stop_target = position.targets[3]

    assert first_target.profit?
    assert second_target.profit?
    assert third_target.profit?
    assert stop_target.stop?
  end

  test "create_targets creates 4 targets with the correct multipliers" do
    position = Position.create!(position_obj)
    position.create_targets

    first_target = position.targets[0]
    second_target = position.targets[1]
    third_target = position.targets[2]
    stop_target = position.targets[3]

    assert first_target.multiplier == 1.0
    assert second_target.multiplier == 2.0
    assert third_target.multiplier == 3.0
    assert stop_target.multiplier.nil?
  end

  test "create_targets creates 4 targets with the correct quantities" do
    position = Position.create!(position_obj)
    position.create_targets

    first_target = position.targets[0]
    second_target = position.targets[1]
    third_target = position.targets[2]
    stop_target = position.targets[3]

    assert first_target.quantity == 200
    assert second_target.quantity == 200
    assert third_target.quantity == 200
    assert stop_target.quantity == position.initial_quantity
  end

  test "create_targets creates 4 targets with the correct prices" do
    position = Position.create!(position_obj)
    position.create_targets

    first_target = position.targets[0]
    second_target = position.targets[1]
    third_target = position.targets[2]
    stop_target = position.targets[3]

    assert first_target.price == 30.50
    assert second_target.price == 31.00
    assert third_target.price == 31.50
    assert stop_target.price == 29.50
  end

  test "create_targets creates 4 targets with the correct prices if it is a short position" do
    new_attrs = {
      side: :short,
      initial_stop_price: 30.50
    }
    position = Position.create!(position_obj(new_attrs))
    position.create_targets

    first_target = position.targets[0]
    second_target = position.targets[1]
    third_target = position.targets[2]
    stop_target = position.targets[3]

    assert first_target.price == 29.50
    assert second_target.price == 29.00
    assert third_target.price == 28.50
    assert stop_target.price == 30.50
  end

  test "create_targets creates 4 targets with the correct prices when initial_filled_avg_price is different from initial_price" do
    new_attrs = { initial_filled_avg_price: 30.10, risk_per_share: 0.6 }
    position = Position.create!(position_obj(new_attrs))
    position.create_targets

    first_target = position.targets[0]
    second_target = position.targets[1]
    third_target = position.targets[2]
    stop_target = position.targets[3]

    assert first_target.price == 30.70
    assert second_target.price == 31.30
    assert third_target.price == 31.90
    assert stop_target.price == 29.50
  end

  test "create_targets creates 4 targets with the correct quantities with an odd number" do
    new_quantity = 667
    risk_per_share = 0.45
    position = Position.create!(position_obj({
      initial_quantity: new_quantity,
      current_quantity: new_quantity,
      risk_per_share: risk_per_share
    }))
    position.create_targets

    assert position.initial_quantity == new_quantity
    assert position.current_quantity == new_quantity
    assert position.risk_per_share == risk_per_share

    first_target = position.targets[0]
    second_target = position.targets[1]
    third_target = position.targets[2]
    stop_target = position.targets[3]

    assert first_target.quantity == 222
    assert second_target.quantity == 222
    assert third_target.quantity == 223
    assert stop_target.quantity == new_quantity
  end

  test "update_quantity_from_order sets current_quantity" do
    position = positions(:one)
    assert position.open?
    assert position.current_quantity == 600

    total_quantity = 300

    position.update_quantity_from_order(total_quantity)

    assert position.open?
    assert position.current_quantity == 300
  end

  test "update_quantity_from_order sets current_quantity and closes the position" do
    position = positions(:one)
    assert position.open?
    assert position.current_quantity == 600

    total_quantity = 0

    position.update_quantity_from_order(total_quantity)

    assert position.closed?
    assert position.current_quantity == 0
  end

  test "update_quantity_from_order does not change current_quantity if the quantity has not changed" do
    position = positions(:one)
    assert position.open?
    assert position.current_quantity == 600

    total_quantity = 600

    position.update_quantity_from_order(total_quantity)

    assert position.open?
    assert position.current_quantity == 600    
  end

  test "create_state works" do
    position = positions(:one)
    position_state = position.create_state
    
    assert position_state.has_key?('risk_per_share')
    assert position_state.has_key?('profit_targets')
    assert position_state.has_key?('stop_target')
    
    just_position_state = get_just_position_state(position_state)
    assert just_position_state == position.attributes
  end

  test "can not create an additional open position for the same symbol" do
    position = positions(:one)
    assert position.open?
    assert position.symbol == 'GME'

    new_attrs = { side: :short, symbol: 'GME' }
    new_position = Position.new(position_obj(new_attrs))
    assert new_position.open?
    assert new_position.symbol == 'GME'

    assert_not new_position.valid?
    assert_not new_position.errors[:symbol].empty?
  end

  test "add_risk_per_share works" do
    new_attrs = { risk_per_share: 0.0 }
    position = Position.new(position_obj(new_attrs))

    assert position.risk_per_share == 0
    assert_not position.initial_filled_avg_price.nil?
    assert_not position.initial_stop_price.nil?
    actual_risk_per_share = position.initial_filled_avg_price - position.initial_stop_price

    position.add_risk_per_share
    assert position.risk_per_share == actual_risk_per_share
  end

  test "calculate_profit_or_loss works with all profit targets filled" do
    position = Position.create!(position_obj)
    position.create_targets

    first_target = position.targets[0]
    assert first_target.profit?

    second_target = position.targets[1]
    assert second_target.profit?

    third_target = position.targets[2]
    assert third_target.profit?

    stop_target = position.targets[3]
    assert stop_target.stop?

    total_quantity = 400
    filled_avg_price = first_target.price
    first_target.update_from_order(total_quantity, filled_avg_price)
    assert first_target.filled?
    first_target_gross_earnings = first_target.filled_avg_price * first_target.quantity

    total_quantity = 200
    filled_avg_price = second_target.price
    second_target.update_from_order(total_quantity, filled_avg_price)
    assert second_target.filled?
    second_target_gross_earnings = second_target.filled_avg_price * second_target.quantity

    total_quantity = 0
    filled_avg_price = third_target.price
    third_target.update_from_order(total_quantity, filled_avg_price)
    assert third_target.filled?
    third_target_gross_earnings = third_target.filled_avg_price * third_target.quantity

    targets_gross_earnings = first_target_gross_earnings + second_target_gross_earnings + third_target_gross_earnings
    assert position.calculate_profit_or_loss == targets_gross_earnings
  end

  test "calculate_profit_or_loss works with two profit targets and stop filled" do
    position = Position.create!(position_obj)
    position.create_targets

    first_target = position.targets[0]
    assert first_target.profit?

    second_target = position.targets[1]
    assert second_target.profit?

    stop_target = position.targets[3]
    assert stop_target.stop?

    total_quantity = 400
    filled_avg_price = first_target.price
    first_target.update_from_order(total_quantity, filled_avg_price)
    assert first_target.filled?
    first_target_gross_earnings = first_target.filled_avg_price * first_target.quantity

    total_quantity = 200
    filled_avg_price = second_target.price
    second_target.update_from_order(total_quantity, filled_avg_price)
    assert second_target.filled?
    second_target_gross_earnings = second_target.filled_avg_price * second_target.quantity

    total_quantity = 0
    filled_avg_price = stop_target.price
    stop_target.update_from_order(total_quantity, filled_avg_price)
    assert stop_target.filled?
    stop_target_gross_earnings = stop_target.filled_avg_price * stop_target.quantity

    targets_gross_earnings = (first_target_gross_earnings + second_target_gross_earnings) - stop_target_gross_earnings
    assert position.calculate_profit_or_loss == targets_gross_earnings
  end

  def get_just_position_state(position_state)
    position_state.select { |key, value| !['profit_targets', 'stop_target'].include?(key) }
  end

  def position_obj(attrs = {})
    {
      status: :open,
      initial_quantity: 600,
      symbol: 'AMC',
      side: :long,
      current_quantity: 600,
      initial_price: 30.0,
      risk_per_share: 0.50,
      initial_filled_avg_price: 30.0,
      initial_stop_price: 29.50
    }.deep_merge(attrs)
  end
end
