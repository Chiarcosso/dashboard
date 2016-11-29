class CreateTransportDocuments < ActiveRecord::Migration[5.0]
  def change
    create_table :transport_documents do |t|
      t.string :number
      t.date :date
      t.string :reason
      
      t.timestamps
    end
  end
end
