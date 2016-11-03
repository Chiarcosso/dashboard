require 'test_helper'

class UserControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get user_new_url
    assert_response :success
  end

  test "should get index" do
    get user_index_url
    assert_response :success
  end

  test "should get show" do
    get user_show_url
    assert_response :success
  end

  test "should get create" do
    get user_create_url
    assert_response :success
  end

  test "should get modify" do
    get user_modify_url
    assert_response :success
  end

  test "should get delete" do
    get user_delete_url
    assert_response :success
  end

end
