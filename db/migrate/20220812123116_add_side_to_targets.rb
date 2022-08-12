class AddSideToTargets < ActiveRecord::Migration[7.0]
  def change
    add_column :targets, :side, :integer
  end
end
