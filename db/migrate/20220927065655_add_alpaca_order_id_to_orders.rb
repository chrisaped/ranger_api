class AddAlpacaOrderIdToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :alpaca_order_id, :string
  end
end
