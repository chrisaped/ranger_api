class AddCategoryToTargets < ActiveRecord::Migration[7.0]
  def change
    add_column :targets, :category, :integer
  end
end
