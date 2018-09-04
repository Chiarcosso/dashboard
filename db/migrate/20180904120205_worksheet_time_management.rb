class WorksheetTimeManagement < ActiveRecord::Migration[5.0]
  def change
    add_column :worksheets, :last_starting_time, :datetime
    add_column :worksheets, :last_stopping_time, :datetime
    add_column :worksheets, :paused, :boolean, null: false, default: true
  end
end
