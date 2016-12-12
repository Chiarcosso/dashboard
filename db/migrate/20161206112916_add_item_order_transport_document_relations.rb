class AddItemOrderTransportDocumentRelations < ActiveRecord::Migration[5.0]
  def change
    add_reference :items, :transport_document, foreign_key: true
  end
end
