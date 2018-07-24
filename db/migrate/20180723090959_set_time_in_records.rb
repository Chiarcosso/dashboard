class SetTimeInRecords < ActiveRecord::Migration[5.0]
  def change
    add_column :presence_records, :set_day_time, :integer
  end
end
