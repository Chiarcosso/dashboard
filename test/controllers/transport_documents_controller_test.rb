require 'test_helper'

class TransportDocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @transport_document = transport_documents(:one)
  end

  test "should get index" do
    get transport_documents_url
    assert_response :success
  end

  test "should get new" do
    get new_transport_document_url
    assert_response :success
  end

  test "should create transport_document" do
    assert_difference('TransportDocument.count') do
      post transport_documents_url, params: { transport_document: { date: @transport_document.date, number: @transport_document.number, reason: @transport_document.reason } }
    end

    assert_redirected_to transport_document_url(TransportDocument.last)
  end

  test "should show transport_document" do
    get transport_document_url(@transport_document)
    assert_response :success
  end

  test "should get edit" do
    get edit_transport_document_url(@transport_document)
    assert_response :success
  end

  test "should update transport_document" do
    patch transport_document_url(@transport_document), params: { transport_document: { date: @transport_document.date, number: @transport_document.number, reason: @transport_document.reason } }
    assert_redirected_to transport_document_url(@transport_document)
  end

  test "should destroy transport_document" do
    assert_difference('TransportDocument.count', -1) do
      delete transport_document_url(@transport_document)
    end

    assert_redirected_to transport_documents_url
  end
end
