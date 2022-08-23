class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.integer :side
      t.string :symbol
      t.json :raw_order
      t.integer :quantity
      t.decimal :price, precision: 6, scale: 2
      t.references :position, null: false, foreign_key: true

      t.timestamps
    end
  end
end
