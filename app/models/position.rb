class Position < ApplicationRecord
  has_many :orders
  has_many :targets

  enum status: %i[open closed], _default: :open
  enum side: %i[long short]

  after_create :create_targets

  def update_quantity_from_order(total_quantity)
    self.current_quantity = total_quantity

    close_if_zero_quantity

    self.save!
    self
  end

  private

  def close_if_zero_quantity
    self.status = :closed if current_quantity == 0
  end

  def create_targets
    multipliers = Target::MULTIPLIERS
    
    multipliers.each do |multiplier|
      last_multiplier = multipliers[-1]
      multipliers_length = multipliers.length

      # profit targets
      self.targets.create!(
        quantity: set_target_quantity(multiplier, last_multiplier, multipliers_length),
        price: set_target_price(multiplier),
        multiplier: multiplier,
        category: :profit
      )
    end

    # stop target
    self.targets.create!(
      quantity: initial_quantity,
      price: stop_price,
      category: :stop
    )
  end

  def set_target_quantity(multiplier, last_multiplier, multipliers_length)
    partial_quantity = (1/last_multiplier * initial_quantity).to_i
    remaining_quantity = initial_quantity - (partial_quantity * (multipliers_length - 1))

    multiplier == last_multiplier ? remaining_quantity : partial_quantity
  end

  def set_target_price(multiplier)
    initial_price + (risk_per_share * multiplier)
  end

  def stop_price
    initial_price - risk_per_share
  end
end
