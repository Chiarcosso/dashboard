class WorksheetSuspended < ActiveRecord::Migration[5.0]
  def change
    add_column :worksheets, :suspended, :boolean, null: false, default: false, index: true
  end
end
