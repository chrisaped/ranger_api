class AddInitialPriceToPosition < ActiveRecord::Migration[7.0]
  def change
    add_column :positions, :initial_price, :decimal, precision: 6, scale: 2
  end
end
