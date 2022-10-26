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

  def find_position_profit_targets
    position.targets.select { |target| target.profit? }.sort_by(&:multiplier)
  end

  def update_stop(stop, total_quantity)
    stop.update_columns(
      quantity: total_quantity,
      price: determine_new_stop_price,
      updated_at: Time.now
    )
  end

  def determine_new_stop_price
    all_profit_targets = find_position_profit_targets

    if all_profit_targets.first.id == id
      position.initial_filled_avg_price
    else
      target_index = 0

      all_profit_targets.each_with_index do |profit_target, index|
        next if index == 0
        if profit_target.id == id
          target_index = index - 1
        end
      end

      previous_profit_target = all_profit_targets[target_index]
      
      previous_profit_target.filled_avg_price
    end
  end

  def add_side
    self.side = position.long? ? :sell : :buy
  end
end
