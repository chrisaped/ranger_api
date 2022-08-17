require "test_helper"

class TargetTest < ActiveSupport::TestCase
  test "can create a new target" do
    position = positions(:one)

    assert_difference -> { Target.count } => 1 do
      position.targets.create!(
        quantity: 100,
        price: 30.0,
        multiplier: 2.5
      )
    end
  end

  test "has proper side if long position" do
    position = positions(:one)
    assert position.long?

    target = Target.create!(target_obj({ position: position }))

    assert target.sell?
  end

  test "has proper side if short position" do
    position = positions(:two)
    assert position.short?

    target = Target.create!(target_obj({ position: position }))

    assert target.buy?
  end

  test "update_from_order works for first profit target" do
    position = positions(:one)
    assert position.targets.length == 4

    first_target = position.targets.first
    assert_not first_target.filled?
    assert first_target.quantity == 200
    assert first_target.price == 30.50
    assert first_target.sell?
    assert first_target.profit?

    assert sell_order_json_obj.dig('qty').to_i == first_target.quantity
    assert sell_order_json_obj.dig('price').to_d == first_target.price
    assert sell_order_json_obj.dig('order', 'side') == first_target.side
    assert sell_order_json_obj.dig('order', 'order_type') == 'limit'
    assert sell_order_json_obj.dig('order', 'status') == 'filled'

    stop_target = position.targets[3]
    stop_target_id = stop_target.id
    assert stop_target.stop?
    assert stop_target.quantity == position.initial_quantity
    assert stop_target.price == (position.initial_price - position.risk_per_share)
    assert stop_target.sell?

    total_quantity = sell_order_json_obj.dig('position_qty').to_i

    first_target.update_from_order(total_quantity)
    assert first_target.filled?

    stop_target = Target.find(stop_target_id)
    assert stop_target.quantity == total_quantity
    assert stop_target.price == (first_target.price - position.risk_per_share)
  end

  test "update_from_order works, and does not update the stop target if the last profit target has been filled" do
    position = positions(:one)
    assert position.targets.length == 4

    first_target = position.targets.first
    assert first_target.profit?

    second_target = position.targets[1]
    assert second_target.profit?

    third_target = position.targets[2]
    assert third_target.profit?

    stop_target = position.targets[3]
    assert stop_target.stop?
    stop_target_id = stop_target.id

    total_quantity = 400
    first_target.update_from_order(total_quantity)
    assert first_target.filled?

    stop_target = Target.find(stop_target_id)
    assert stop_target.quantity == total_quantity
    assert stop_target.price == (first_target.price - position.risk_per_share)

    total_quantity = 200
    second_target.update_from_order(total_quantity)
    assert second_target.filled?

    stop_target = Target.find(stop_target_id)
    assert stop_target.quantity == total_quantity
    assert stop_target.price == (second_target.price - position.risk_per_share)

    position.closed!
    assert position.closed?

    total_quantity = 0
    third_target.update_from_order(total_quantity)
    assert third_target.filled?

    stop_target = Target.find(stop_target_id)
    assert stop_target.quantity == third_target.quantity
    assert stop_target.price == (second_target.price - position.risk_per_share)
  end

  def sell_order_json_obj(attrs = {})
    file = File.join(Rails.root, 'test', 'data_samples', 'sell_order.json')
    json = File.read(file)
    json_obj = JSON.parse(json)
    json_obj.deep_merge(attrs)
  end

  def target_obj(attrs = {})
    {
      quantity: 20,
      price: 500.0,
      multiplier: 2.0
    }.deep_merge(attrs)
  end
end
