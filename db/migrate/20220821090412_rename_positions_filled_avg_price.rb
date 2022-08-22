class RenamePositionsFilledAvgPrice < ActiveRecord::Migration[7.0]
  def change
    rename_column :positions, :filled_avg_price, :initial_filled_avg_price
  end
end
