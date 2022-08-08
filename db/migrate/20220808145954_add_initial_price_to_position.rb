class AddInitialPriceToPosition < ActiveRecord::Migration[7.0]
  def change
    add_column :positions, :initial_price, :decimal
  end
end
