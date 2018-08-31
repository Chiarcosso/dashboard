class FixWorkshopOperation < ActiveRecord::Migration[5.0]
  def change
    add_column :workshop_operations, :paused, :boolean, null: false, default: true
    add_column :workshop_operations, :last_starting_time, :datetime, null: true
    add_column :workshop_operations, :last_stopping_time, :datetime, null: true
  end
end
