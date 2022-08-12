require "test_helper"

class TargetTest < ActiveSupport::TestCase
  test "can create a new target" do
    position = positions(:one)

    assert_difference -> { Target.count } => 1 do
      position.targets.create!(
        quantity: 100,
        price: 30.0,
        multiplier: 2.0
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

  def target_obj(attrs = {})
    {
      quantity: 20,
      price: 500.0,
      multiplier: 2.0
    }.deep_merge(attrs)
  end
end
