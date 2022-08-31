require "test_helper"

class PositionsControllerTest < ActionDispatch::IntegrationTest
  test "create_position works" do
    assert_difference -> { Position.count } => 1 do
      post create_position_path, params: position_params
    end

    assert_equal 201, @response.status
  end

  test "cancel_position works" do
    position = positions(:one)
    assert position.open?

    put cancel_position_path, params: cancel_position_params do
      assert position.canceled?
    end

    assert_equal 200, @response.status
  end

  test "get_positions works" do
    get get_positions_path
    
    positions = Position.open.order(:created_at).map(&:create_state)

    assert_equal positions.to_json, @response.body
  end

  test "get_total_profit_or_loss_today works" do
    get get_total_profit_or_loss_today_path
    
    assert_equal Position.total_profit_or_loss_today.to_s, @response.body
  end

  test "get_all_closed_positions works" do
    get get_all_closed_positions_path
    
    positions = Position.closed.order(created_at: :desc).map(&:create_state)

    assert_equal positions.to_json, @response.body
  end

  def position_params
    {"side"=>"buy", "symbol"=>"AMC", "type"=>"limit", "limit_price"=>"20.01", "qty"=>"1374", "time_in_force"=>"gtc", "stop_price"=>"19.76", "position"=>{"symbol"=>"AMC", "side"=>"buy"}}
  end

  def cancel_position_params
    {"symbol"=>"GME", "position"=>{"symbol"=>"GME"}}
  end
end
