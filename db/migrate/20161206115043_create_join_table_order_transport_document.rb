class CreateJoinTableOrderTransportDocument < ActiveRecord::Migration[5.0]
  def change
    create_join_table :orders, :transport_documents do |t|
      # t.index [:order_id, :transport_document_id]
      # t.index [:transport_document_id, :order_id]
    end
  end
end
