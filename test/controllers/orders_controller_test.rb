require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "create_order works" do
    assert_difference -> { Order.count } => 1 do
      post create_order_path, params: order_params
    end

    assert_equal 201, @response.status
  end

  def order_params
    file = File.join(Rails.root, 'test', 'data_samples', "new_order.json")
    json = File.read(file)
    json_obj = JSON.parse(json)
  end
end
