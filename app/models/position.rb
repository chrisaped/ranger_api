class Position < ApplicationRecord
  has_many :orders
  has_many :targets

  enum status: %i[open closed], _default: :open
  enum side: %i[long short]

  after_create :create_targets

  def update_quantity_from_order(order_side, order_quantity)
    if is_same_side_as_order(order_side)
      self.current_quantity += order_quantity
    else
      self.current_quantity -= order_quantity
    end

    close_if_zero_quantity
  end

  private

  def is_same_side_as_order(order_side)
    order_side = determine_order_side(order_side)
    order_side == side
  end

  def determine_order_side(order_side)
    order_side == 'buy' ? 'long' : 'short'
  end

  def close_if_zero_quantity
    self.status = :closed if current_quantity == 0
  end

  def create_targets
    multipliers = Target::MULTIPLIERS
    multipliers.each do |multiplier|
      last_multiplier = multipliers[-1]
      multipliers_length = multipliers.length

      self.targets.create!(
        quantity: set_target_quantity(multiplier, last_multiplier, multipliers_length),
        price: set_target_price(multiplier),
        multiplier: multiplier
      )
    end
  end

  def set_target_quantity(multiplier, last_multiplier, multipliers_length)
    partial_quantity = (1/last_multiplier * initial_quantity).to_i
    remaining_quantity = initial_quantity - (partial_quantity * (multipliers_length - 1))

    multiplier == last_multiplier ? remaining_quantity : partial_quantity
  end

  def set_target_price(multiplier)
    initial_price + (risk_per_share * multiplier)
  end
end
