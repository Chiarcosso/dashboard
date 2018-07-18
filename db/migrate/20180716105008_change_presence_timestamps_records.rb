class ChangePresenceTimestampsRecords < ActiveRecord::Migration[5.0]
  def change
    add_column :presence_timestamps, :entering, :boolean
    add_column :presence_records, :calculated_start, :datetime, null: false
    add_column :presence_records, :calculated_end, :datetime
  end
end
