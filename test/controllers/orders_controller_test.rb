require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "create_order works" do
    Position.create!(position_obj)
    
    new_attrs = {
      "order" => {
        "symbol" => "AMC"
      }
    }
    new_order_params = order_params(new_attrs)

    assert_difference -> { Order.count } => 1 do
      post create_order_path, params: new_order_params
    end

    assert_equal 201, @response.status
  end

  test "create_order does not create a duplicate order" do
    Position.create!(position_obj)
    
    new_attrs = {
      "order" => {
        "symbol" => "AMC"
      }
    }
    new_order_params = order_params(new_attrs)

    assert_difference -> { Order.count } => 1 do
      post create_order_path, params: new_order_params
    end

    assert_equal 201, @response.status

    assert_difference -> { Order.count } => 0 do
      post create_order_path, params: new_order_params
    end

    assert_equal 400, @response.status
  end

  def order_params(attrs = {})
    file = File.join(Rails.root, 'test', 'data_samples', "new_order.json")
    json = File.read(file)
    json_obj = JSON.parse(json)
    json_obj.deep_merge(attrs)
  end

  def position_obj(attrs = {})
    {
      status: :open,
      initial_quantity: 600,
      symbol: 'AMC',
      side: :long,
      current_quantity: 600,
      initial_price: 30.0,
      risk_per_share: 0.50,
      initial_filled_avg_price: 30.0,
      initial_stop_price: 29.50
    }.deep_merge(attrs)
  end
end
