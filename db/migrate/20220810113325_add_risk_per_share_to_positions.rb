class AddRiskPerShareToPositions < ActiveRecord::Migration[7.0]
  def change
    add_column :positions, :risk_per_share, :decimal, precision: 6, scale: 2
  end
end
