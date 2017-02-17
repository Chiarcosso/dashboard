require 'test_helper'

class VehicleInformationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @vehicle_information = vehicle_informations(:one)
  end

  test "should get index" do
    get vehicle_informations_url
    assert_response :success
  end

  test "should get new" do
    get new_vehicle_information_url
    assert_response :success
  end

  test "should create vehicle_information" do
    assert_difference('VehicleInformation.count') do
      post vehicle_informations_url, params: { vehicle_information: { date: @vehicle_information.date, information: @vehicle_information.information, information_type: @vehicle_information.information_type, vehicle_id: @vehicle_information.vehicle_id } }
    end

    assert_redirected_to vehicle_information_url(VehicleInformation.last)
  end

  test "should show vehicle_information" do
    get vehicle_information_url(@vehicle_information)
    assert_response :success
  end

  test "should get edit" do
    get edit_vehicle_information_url(@vehicle_information)
    assert_response :success
  end

  test "should update vehicle_information" do
    patch vehicle_information_url(@vehicle_information), params: { vehicle_information: { date: @vehicle_information.date, information: @vehicle_information.information, information_type: @vehicle_information.information_type, vehicle_id: @vehicle_information.vehicle_id } }
    assert_redirected_to vehicle_information_url(@vehicle_information)
  end

  test "should destroy vehicle_information" do
    assert_difference('VehicleInformation.count', -1) do
      delete vehicle_information_url(@vehicle_information)
    end

    assert_redirected_to vehicle_informations_url
  end
end
