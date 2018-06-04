class StationToWorksheet < ActiveRecord::Migration[5.0]
  def change
    add_column :worksheets, :station, :string, null: true, index: true
  end
end
