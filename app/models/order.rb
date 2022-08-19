class Order < ApplicationRecord
  belongs_to :position

  enum side: %i[buy sell]

  def update_position(json_obj)
    position = Position.find_by(status: :open, symbol: symbol)

    if position.nil?
      puts "position not found"
    else
      # position exists
      total_quantity = json_obj.dig('position_qty').to_i

      position = position.update_quantity_from_order(total_quantity)
      
      update_position_targets(json_obj, total_quantity, position)
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
      puts "no applicable target"
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
