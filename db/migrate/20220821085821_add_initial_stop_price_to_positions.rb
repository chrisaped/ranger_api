class AddInitialStopPriceToPositions < ActiveRecord::Migration[7.0]
  def change
    add_column :positions, :initial_stop_price, :float
  end
end
