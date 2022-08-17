class Order < ApplicationRecord
  belongs_to :position

  enum side: %i[buy sell]

  def create_or_update_position(risk_per_share, json_obj)
    position = Position.find_by(status: :open, symbol: symbol)

    if position.nil?
      position = create_position(risk_per_share)
      # create first oco order
    else
      # position exists
      total_quantity = json_obj.dig('position_qty').to_i

      position = position.update_quantity_from_order(total_quantity)
      
      update_position_targets(json_obj, total_quantity, position)

      # create another oco order
    end

    self.position = position
  end

  private

  def update_position_targets(json_obj, total_quantity, position)
    order_type = json_obj.dig('order', 'type')
    target = find_target(order_type, position)

    if target
      target.update_from_order(total_quantity)
    else
      puts "no target found"
    end
  end

  def find_target(order_type, position)
    Target.find_by(
      quantity: quantity,
      price: price,
      position: position, 
      filled: false, 
      side: side, 
      category: determine_target_category(order_type)
    )
  end

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

  def determine_target_category(order_type)
    case order_type
    when 'limit'
      :profit
    when 'stop'
      :stop
    else
      puts "order_type not supported: #{order_type}"
    end    
  end
end
