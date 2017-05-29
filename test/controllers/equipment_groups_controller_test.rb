require 'test_helper'

class EquipmentGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @equipment_group = equipment_groups(:one)
  end

  test "should get index" do
    get equipment_groups_url
    assert_response :success
  end

  test "should get new" do
    get new_equipment_group_url
    assert_response :success
  end

  test "should create equipment_group" do
    assert_difference('EquipmentGroup.count') do
      post equipment_groups_url, params: { equipment_group: { name: @equipment_group.name } }
    end

    assert_redirected_to equipment_group_url(EquipmentGroup.last)
  end

  test "should show equipment_group" do
    get equipment_group_url(@equipment_group)
    assert_response :success
  end

  test "should get edit" do
    get edit_equipment_group_url(@equipment_group)
    assert_response :success
  end

  test "should update equipment_group" do
    patch equipment_group_url(@equipment_group), params: { equipment_group: { name: @equipment_group.name } }
    assert_redirected_to equipment_group_url(@equipment_group)
  end

  test "should destroy equipment_group" do
    assert_difference('EquipmentGroup.count', -1) do
      delete equipment_group_url(@equipment_group)
    end

    assert_redirected_to equipment_groups_url
  end
end
