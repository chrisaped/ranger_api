class AddFilledAvgPrice < ActiveRecord::Migration[7.0]
  def change
    add_column :positions, :filled_avg_price, :float
    add_column :targets, :filled_avg_price, :float
    add_column :orders, :filled_avg_price, :float
  end
end
