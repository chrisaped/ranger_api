class AddNoTargetSellFilledAvgPriceToPositions < ActiveRecord::Migration[7.0]
  def change
    add_column :positions, :no_target_sell_filled_avg_price, :decimal, precision: 6, scale: 2
  end
end
