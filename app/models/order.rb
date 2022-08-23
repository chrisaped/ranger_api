class Order < ApplicationRecord
  belongs_to :position

  enum side: %i[buy sell]

  def update_position(json_obj)
    position = Position.find_by(status: :open, symbol: symbol)
    raise "position not found" if position.nil?

    total_quantity = json_obj.dig('position_qty').to_i
    position.update_quantity_from_order(total_quantity)

    if position.initial_filled_avg_price.nil?
      position.initial_filled_avg_price = filled_avg_price
    end
  
    position.add_risk_per_share if position.risk_per_share.nil?

    position.save!
    
    create_or_update_position_targets(json_obj, total_quantity, position)

    self.position = position
  end

  private

  def create_or_update_position_targets(json_obj, total_quantity, position)
    if position.targets.length > 0
      order_type = json_obj.dig('order', 'type')
      target = find_target(order_type, position)
      raise "target not found" if target.nil?
      target.update_from_order(total_quantity)
    else
      position.create_targets
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
