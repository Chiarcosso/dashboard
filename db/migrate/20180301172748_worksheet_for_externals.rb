class WorksheetForExternals < ActiveRecord::Migration[5.0]
  def change
    remove_foreign_key :worksheets, column: :vehicle_id if foreign_key_exists? :worksheets, column: :vehicle_id
    add_column :worksheets, :vehicle_type, :string, null: false, index: true, default: 'Vehicle'
  end
end
