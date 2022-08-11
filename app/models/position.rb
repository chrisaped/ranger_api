class Position < ApplicationRecord
  has_many :orders
  has_many :targets

  enum status: %i[open closed], _default: :open
  enum side: %i[long short]

  after_create :create_targets

  private

  def create_targets
    Target::MULTIPLIERS.each do |multiplier|
      self.targets.create!(
        quantity: set_target_quantity(multiplier),
        price: set_target_price(multiplier),
        multiplier: multiplier
      )
    end
  end

  def set_target_quantity(multiplier)
    one_third_quantity = (1/3.0 * initial_quantity).to_i
    remaining_quantity = initial_quantity - (one_third_quantity + one_third_quantity)

    case multiplier
    when 1.0
      one_third_quantity
    when 2.0
      one_third_quantity
    when 3.0
      remaining_quantity
    else
      one_third_quantity
    end
  end

  def set_target_price(multiplier)
    case multiplier
    when 1.0
      initial_price + risk_per_share
    when 2.0
      initial_price + (risk_per_share * 2)
    when 3.0
      initial_price + (risk_per_share * 3)
    else
      initial_price + risk_per_share
    end
  end
end
