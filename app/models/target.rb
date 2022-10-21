class Target < ApplicationRecord
  belongs_to :position

  enum side: %i[buy sell]
  enum category: %i[profit stop]

  MULTIPLIERS = [0.5, 1.0, 1.5]

  before_create :add_side

  def update_from_order(total_quantity, filled_avg_price)
    self.update_columns(
      filled: true, 
      filled_avg_price: filled_avg_price,
      updated_at: Time.now
    )

    if profit? && position.open?
      stop = find_position_stop
      update_stop(stop, total_quantity) if stop
    end
  end

  private

  def find_position_stop
    position.targets.select { |target| target.stop? }.first
  end

  def update_stop(stop, total_quantity)
    stop.update_columns(
      quantity: total_quantity,
      price: calculate_new_stop_price,
      updated_at: Time.now
    )
  end

  def calculate_new_stop_price
    if position.long?
      price - position.risk_per_share
    else
      price + position.risk_per_share
    end
  end

  def add_side
    self.side = position.long? ? :sell : :buy
  end
end
