require 'test_helper'

class ExternalVehiclesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @external_vehicle = external_vehicles(:one)
  end

  test "should get index" do
    get external_vehicles_url
    assert_response :success
  end

  test "should get new" do
    get new_external_vehicle_url
    assert_response :success
  end

  test "should create external_vehicle" do
    assert_difference('ExternalVehicle.count') do
      post external_vehicles_url, params: { external_vehicle: { owner_id: @external_vehicle.owner_id, plate: @external_vehicle.plate, vehicle_type_id: @external_vehicle.vehicle_type_id, vehicle_typology_id: @external_vehicle.vehicle_typology_id } }
    end

    assert_redirected_to external_vehicle_url(ExternalVehicle.last)
  end

  test "should show external_vehicle" do
    get external_vehicle_url(@external_vehicle)
    assert_response :success
  end

  test "should get edit" do
    get edit_external_vehicle_url(@external_vehicle)
    assert_response :success
  end

  test "should update external_vehicle" do
    patch external_vehicle_url(@external_vehicle), params: { external_vehicle: { owner_id: @external_vehicle.owner_id, plate: @external_vehicle.plate, vehicle_type_id: @external_vehicle.vehicle_type_id, vehicle_typology_id: @external_vehicle.vehicle_typology_id } }
    assert_redirected_to external_vehicle_url(@external_vehicle)
  end

  test "should destroy external_vehicle" do
    assert_difference('ExternalVehicle.count', -1) do
      delete external_vehicle_url(@external_vehicle)
    end

    assert_redirected_to external_vehicles_url
  end
end
