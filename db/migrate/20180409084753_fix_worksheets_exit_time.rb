class FixWorksheetsExitTime < ActiveRecord::Migration[5.0]
  def change
    add_column :worksheets, :exit_time, :datetime, null: true
  end
end
