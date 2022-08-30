class Position < ApplicationRecord
  has_many :orders
  has_many :targets

  enum status: %i[open closed], _default: :open
  enum side: %i[long short]

  validate :prevent_duplicate_open_position, on: :create

  def add_risk_per_share
    self.risk_per_share = calculate_risk_per_share
  end

  def update_quantity_from_order(total_quantity)
    if current_quantity != total_quantity
      self.current_quantity = total_quantity
      close_if_zero_quantity
    end    
  end

  def create_state
    position_state_obj = convert_to_hash_with_floats(self)
    
    profit_targets = targets.select { |target| target.profit? }.sort_by(&:created_at)
    if profit_targets.length > 0
      converted_profit_targets = profit_targets.map do |profit_target|
        convert_to_hash_with_floats(profit_target)
      end
      position_state_obj['profit_targets'] = converted_profit_targets
    end
    
    stop_target = targets.select { |target| target.stop? }&.first
    if stop_target
      converted_stop_target = convert_to_hash_with_floats(stop_target)
      position_state_obj['stop_target'] = converted_stop_target
    end

    position_state_obj['gross_earnings'] = calculate_gross_earnings

    position_state_obj
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
      price: initial_stop_price,
      category: :stop
    )
  end

  def calculate_gross_earnings
    gross_earnings = 0.0
    filled_targets = targets.select { |target| target.filled? }

    if filled_targets.length > 0
      filled_targets.each do |filled_target|
        gross_amount = filled_target.filled_avg_price * filled_target.quantity
        gross_earnings += gross_amount
      end
    end

    gross_earnings
  end

  def calculate_profit_or_loss
    gross_earnings = calculate_gross_earnings
    initial_cost = initial_quantity * initial_filled_avg_price

    profit_or_loss = if long?
      gross_earnings - initial_cost
    else
      # short
      initial_cost - gross_earnings
    end

    profit_or_loss
  end

  def self.total_profit_or_loss_today
    positions = Position.closed.where(created_at: Date.today.all_day)

    total_profit_or_loss = 0.0

    positions.each do |position|
      total_profit_or_loss += position.calculate_profit_or_loss
    end

    total_profit_or_loss
  end

  private

  def convert_to_hash_with_floats(obj)
    obj.attributes.transform_values do |value|
      value.class == BigDecimal ? value.to_f : value
    end    
  end

  def calculate_risk_per_share
    (initial_filled_avg_price - initial_stop_price).abs
  end

  def prevent_duplicate_open_position
    duplicate_open_position = Position.open.find_by(symbol: symbol)
    errors.add(:symbol, "can't create a duplicate open position") if duplicate_open_position
  end

  def close_if_zero_quantity
    self.status = :closed if current_quantity == 0
  end

  def set_target_quantity(multiplier, last_multiplier, multipliers_length)
    partial_quantity = (1/last_multiplier * initial_quantity).to_i
    remaining_quantity = initial_quantity - (partial_quantity * (multipliers_length - 1))

    multiplier == last_multiplier ? remaining_quantity : partial_quantity
  end

  def set_target_price(multiplier)
    if long?
      initial_filled_avg_price + (risk_per_share * multiplier)
    else
      initial_filled_avg_price - (risk_per_share * multiplier)
    end
  end
end
