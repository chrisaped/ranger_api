class CreateTargets < ActiveRecord::Migration[7.0]
  def change
    create_table :targets do |t|
      t.integer :quantity
      t.decimal :price
      t.float :multiplier
      t.references :position, null: false, foreign_key: true

      t.timestamps
    end
  end
end
