class Target < ApplicationRecord
  belongs_to :position

  enum side: %i[buy sell]
  enum category: %i[profit stop]

  MULTIPLIERS = [1.0, 2.0, 3.0]

  before_create :add_side

  def update_from_order(total_quantity, filled_avg_price)
    self.update_columns(filled: true, filled_avg_price: filled_avg_price)

    if profit?
      stop = find_position_stop
      update_stop(stop, total_quantity) if stop && position.open?
    end
  end

  private

  def find_position_stop
    Target.find_by(
      position: position,
      category: :stop
    )
  end

  def update_stop(stop, total_quantity)
    stop.update_columns(
      quantity: total_quantity,
      price: calculate_new_stop_price 
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
