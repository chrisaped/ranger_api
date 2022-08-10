class AddRiskPerShareToPositions < ActiveRecord::Migration[7.0]
  def change
    add_column :positions, :risk_per_share, :decimal
  end
end
