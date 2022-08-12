class Position < ApplicationRecord
  has_many :orders
  has_many :targets

  enum status: %i[open closed], _default: :open
  enum side: %i[long short]

  after_create :create_targets

  private

  def create_targets
    Target::MULTIPLIERS.each do |multiplier|
      last_multiplier = Target::MULTIPLIERS[-1]
      multipliers_length = Target::MULTIPLIERS.length

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
