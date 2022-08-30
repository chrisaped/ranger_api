class Order < ApplicationRecord
  belongs_to :position

  enum side: %i[buy sell]

  def update_position(json_obj)
    position = Position.find_by(status: :open, symbol: symbol)
    raise "position not found" if position.nil?

    total_quantity = (json_obj.dig('position_qty').to_i).abs
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
      target = find_target(position)
      if target
        target.update_from_order(total_quantity, filled_avg_price) 
      else
        puts "target not found"
        puts "quantity: #{quantity}"
        puts "price: #{price}"
        puts "position: #{position}"
        puts "side: #{side}"
      end
    else
      position.create_targets
    end
  end

  def find_target(position)
    Target.find_by(
      quantity: quantity,
      price: price,
      position: position, 
      filled: false, 
      side: side, 
    )
  end
end
