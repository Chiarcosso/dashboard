class LosToWorksheet < ActiveRecord::Migration[5.0]
  def change
    add_column :worksheets, :log, :text
  end
end
