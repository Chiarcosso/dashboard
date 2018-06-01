class WorksheetDuration < ActiveRecord::Migration[5.0]
  def change
    add_index :worksheets, :code, unique: true
    add_column :worksheets, :real_duration, :integer, null: false, default: 0
    add_column :worksheets, :creation_date, :date, null: true
  end
end
