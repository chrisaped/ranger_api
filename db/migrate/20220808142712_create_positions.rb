class CreatePositions < ActiveRecord::Migration[7.0]
  def change
    create_table :positions do |t|
      t.integer :status
      t.integer :initial_quantity
      t.string :symbol
      t.integer :side
      t.integer :current_quantity

      t.timestamps
    end
  end
end
