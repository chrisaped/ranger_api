class AddFilledAvgPrice < ActiveRecord::Migration[7.0]
  def change
    add_column :positions, :filled_avg_price, :decimal, precision: 6, scale: 2
    add_column :targets, :filled_avg_price, :decimal, precision: 6, scale: 2
    add_column :orders, :filled_avg_price, :decimal, precision: 6, scale: 2
  end
end
