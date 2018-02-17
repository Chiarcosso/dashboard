class CreateMssqlReferences < ActiveRecord::Migration[5.0]
  def change
    create_table :mssql_references do |t|
      t.references :local_object, polymorphic: true, null: false
      t.integer :remote_object_id, null: false
      t.string :remote_object_table, null: false, index: true

      t.timestamps
    end
    add_index :mssql_references, [:local_object_id,:local_object_type,:remote_object_id,:remote_object_table], unique: true, name: :mssql_references_uniques unless index_exists? :mssql_references, [:local_object_id,:local_object_type,:remote_object_id,:remote_object_table], name: :mssql_references_uniques
  end
end
