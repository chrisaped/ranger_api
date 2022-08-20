class ChangeDecimalsToFloats < ActiveRecord::Migration[7.0]
  def change
    change_column :orders, :price, :float
    change_column :positions, :initial_price, :float
    change_column :positions, :risk_per_share, :float
    change_column :targets, :price, :float
  end
end
