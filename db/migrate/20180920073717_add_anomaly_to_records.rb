class AddAnomalyToRecords < ActiveRecord::Migration[5.0]
  def change
    add_column :presence_records, :anomaly, :string, index: true, null: true
  end
end
