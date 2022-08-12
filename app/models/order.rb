class Order < ApplicationRecord
  belongs_to :position

  enum side: %i[buy sell]

  def create_or_update_position(risk_per_share)
    position = Position.find_by(status: :open, symbol: symbol)

    if position.nil?
      position = create_position(risk_per_share)
    else
      # position exists
      update_position(position)
    end

    self.position = position
  end

  private

  def create_position(risk_per_share)
    Position.create!(
      initial_quantity: quantity, 
      symbol: symbol, 
      side: determine_position_side,
      current_quantity: quantity,
      initial_price: price,
      risk_per_share: risk_per_share
    )
  end

  def determine_position_side
    side == 'buy' ? 'long' : 'short'
  end
end
