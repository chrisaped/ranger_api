class AddNoTargetSellFilledQtyToPositions < ActiveRecord::Migration[7.0]
  def change
    add_column :positions, :no_target_sell_filled_qty, :integer
  end
end
