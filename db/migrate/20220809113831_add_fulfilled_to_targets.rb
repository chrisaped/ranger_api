class AddFulfilledToTargets < ActiveRecord::Migration[7.0]
  def change
    add_column :targets, :fulfilled, :boolean, default: false
  end
end
