class PresenceTimestampsFileNull < ActiveRecord::Migration[5.0]
  def change
    change_column :presence_timestamps, :file, :string, null: true, index: true
    change_column :presence_timestamps, :row, :integer, null: true
  end
end
