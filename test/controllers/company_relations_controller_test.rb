require 'test_helper'

class CompanyRelationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @company_relation = company_relations(:one)
  end

  test "should get index" do
    get company_relations_url
    assert_response :success
  end

  test "should get new" do
    get new_company_relation_url
    assert_response :success
  end

  test "should create company_relation" do
    assert_difference('CompanyRelation.count') do
      post company_relations_url, params: { company_relation: { name: @company_relation.name } }
    end

    assert_redirected_to company_relation_url(CompanyRelation.last)
  end

  test "should show company_relation" do
    get company_relation_url(@company_relation)
    assert_response :success
  end

  test "should get edit" do
    get edit_company_relation_url(@company_relation)
    assert_response :success
  end

  test "should update company_relation" do
    patch company_relation_url(@company_relation), params: { company_relation: { name: @company_relation.name } }
    assert_redirected_to company_relation_url(@company_relation)
  end

  test "should destroy company_relation" do
    assert_difference('CompanyRelation.count', -1) do
      delete company_relation_url(@company_relation)
    end

    assert_redirected_to company_relations_url
  end
end
