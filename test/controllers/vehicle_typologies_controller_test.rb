require 'test_helper'

class VehicleTypologiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @vehicle_typology = vehicle_typologies(:one)
  end

  test "should get index" do
    get vehicle_typologies_url
    assert_response :success
  end

  test "should get new" do
    get new_vehicle_typology_url
    assert_response :success
  end

  test "should create vehicle_typology" do
    assert_difference('VehicleTypology.count') do
      post vehicle_typologies_url, params: { vehicle_typology: { name: @vehicle_typology.name } }
    end

    assert_redirected_to vehicle_typology_url(VehicleTypology.last)
  end

  test "should show vehicle_typology" do
    get vehicle_typology_url(@vehicle_typology)
    assert_response :success
  end

  test "should get edit" do
    get edit_vehicle_typology_url(@vehicle_typology)
    assert_response :success
  end

  test "should update vehicle_typology" do
    patch vehicle_typology_url(@vehicle_typology), params: { vehicle_typology: { name: @vehicle_typology.name } }
    assert_redirected_to vehicle_typology_url(@vehicle_typology)
  end

  test "should destroy vehicle_typology" do
    assert_difference('VehicleTypology.count', -1) do
      delete vehicle_typology_url(@vehicle_typology)
    end

    assert_redirected_to vehicle_typologies_url
  end
end
