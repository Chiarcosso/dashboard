class AddWorksheetHours < ActiveRecord::Migration[5.0]
  def change
    add_column :worksheets, :hours, :integer, limit: 4, null: false, default: 0
  end
end
