require 'test_helper'

class PositionCodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @position_code = position_codes(:one)
  end

  test "should get index" do
    get position_codes_url
    assert_response :success
  end

  test "should get new" do
    get new_position_code_url
    assert_response :success
  end

  test "should create position_code" do
    assert_difference('PositionCode.count') do
      post position_codes_url, params: { position_code: { floor: @position_code.floor, level: @position_code.level, row: @position_code.row, section: @position_code.section, sector: @position_code.sector } }
    end

    assert_redirected_to position_code_url(PositionCode.last)
  end

  test "should show position_code" do
    get position_code_url(@position_code)
    assert_response :success
  end

  test "should get edit" do
    get edit_position_code_url(@position_code)
    assert_response :success
  end

  test "should update position_code" do
    patch position_code_url(@position_code), params: { position_code: { floor: @position_code.floor, level: @position_code.level, row: @position_code.row, section: @position_code.section, sector: @position_code.sector } }
    assert_redirected_to position_code_url(@position_code)
  end

  test "should destroy position_code" do
    assert_difference('PositionCode.count', -1) do
      delete position_code_url(@position_code)
    end

    assert_redirected_to position_codes_url
  end
end
