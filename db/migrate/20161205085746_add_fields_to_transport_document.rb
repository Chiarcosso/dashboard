class AddFieldsToTransportDocument < ActiveRecord::Migration[5.0]
  def change
    remove_foreign_key :transport_documents, name: :fk_rails_fb35772273
    remove_column(:transport_documents, :company_id)
    add_reference(:transport_documents, :vector, foreign_key: {to_table: :companies})
    add_reference(:transport_documents, :subvector, foreign_key: {to_table: :companies})
    add_reference(:transport_documents, :receiver, foreign_key: {to_table: :companies})
  end
end
