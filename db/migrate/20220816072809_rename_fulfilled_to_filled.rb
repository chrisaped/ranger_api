class RenameFulfilledToFilled < ActiveRecord::Migration[7.0]
  def change
    rename_column :targets, :fulfilled, :filled
  end
end
