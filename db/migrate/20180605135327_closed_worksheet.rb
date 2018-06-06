class ClosedWorksheet < ActiveRecord::Migration[5.0]
  def change
    add_column :worksheets, :closed, :boolean, null: false, default: false, index: true
  end
end
