class AddInitialStopPriceToPositions < ActiveRecord::Migration[7.0]
  def change
    add_column :positions, :initial_stop_price, :decimal, precision: 6, scale: 2
  end
end
