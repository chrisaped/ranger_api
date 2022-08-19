require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "can create a position" do
    assert_difference -> { Position.count } => 1 do
      Position.create!(position_obj)
    end
  end

  test "4 targets are created after a position is created" do
    assert_difference -> { Position.count } => 1, -> { Target.count } => 4 do
      Position.create!(position_obj)
    end    
  end

  test "4 targets created have the correct categories" do
    position = Position.create!(position_obj)

    first_target = position.targets[0]
    second_target = position.targets[1]
    third_target = position.targets[2]
    stop_target = position.targets[3]

    assert first_target.profit?
    assert second_target.profit?
    assert third_target.profit?
    assert stop_target.stop?
  end

  test "4 targets created have the correct multipliers" do
    position = Position.create!(position_obj)

    first_target = position.targets[0]
    second_target = position.targets[1]
    third_target = position.targets[2]
    stop_target = position.targets[3]

    assert first_target.multiplier == 1.0
    assert second_target.multiplier == 2.0
    assert third_target.multiplier == 3.0
    assert stop_target.multiplier.nil?
  end

  test "4 targets created have the correct quantities" do
    position = Position.create!(position_obj)

    first_target = position.targets[0]
    second_target = position.targets[1]
    third_target = position.targets[2]
    stop_target = position.targets[3]

    assert first_target.quantity == 200
    assert second_target.quantity == 200
    assert third_target.quantity == 200
    assert stop_target.quantity == position.initial_quantity
  end

  test "4 targets have the correct prices" do
    position = Position.create!(position_obj)

    first_target = position.targets[0]
    second_target = position.targets[1]
    third_target = position.targets[2]
    stop_target = position.targets[3]

    assert first_target.price == 30.50
    assert second_target.price == 31.00
    assert third_target.price == 31.50
    assert stop_target.price == 29.50
  end

  test "4 targets created have the correct quantities with an odd number" do
    new_quantity = 667
    risk_per_share = 0.45
    position = Position.create!(position_obj({
      initial_quantity: new_quantity,
      current_quantity: new_quantity,
      risk_per_share: risk_per_share
    }))

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

  test "create_state works" do
    position = positions(:one)
    position_state = position.create_state
    
    assert position_state.has_key?('risk_per_share')
    assert position_state.has_key?('profit_targets')
    assert position_state.has_key?('stop_target')
    
    just_position_state = get_just_position_state(position_state)
    assert just_position_state == position.attributes

    profit_targets = get_profit_targets(position)
    assert position_state['profit_targets'] == profit_targets 

    stop_target = get_stop_target(position)
    assert position_state['stop_target'] == stop_target
  end

  def get_just_position_state(position_state)
    position_state.select { |key, value| !['profit_targets', 'stop_target'].include?(key) }
  end

  def get_profit_targets(position)
    position.targets.select { |target| target.profit? }.sort_by(&:created_at)
  end

  def get_stop_target(position)
    position.targets.select { |target| target.stop? }.first
  end

  def position_obj(attrs = {})
    {
      status: :open,
      initial_quantity: 600,
      symbol: 'GME',
      side: :long,
      current_quantity: 600,
      initial_price: 30.0,
      risk_per_share: 0.50    
    }.deep_merge(attrs)
  end
end
