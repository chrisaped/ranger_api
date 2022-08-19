require "test_helper"

class PositionsControllerTest < ActionDispatch::IntegrationTest
  test "create_position works" do
    assert_difference -> { Position.count } => 1 do
      post create_position_path, params: position_params
    end

    assert_equal 201, @response.status
  end

  test "get_positions works" do
    get get_positions_path

    assert_equal Position.generate_states.to_json, @response.body
  end

  def position_params
    {"side"=>"buy", "symbol"=>"AMC", "type"=>"limit", "limit_price"=>"20.01", "qty"=>"1374", "time_in_force"=>"gtc", "stop_price"=>"19.76", "position"=>{"symbol"=>"AMC", "side"=>"buy"}}
  end
end
