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
end
