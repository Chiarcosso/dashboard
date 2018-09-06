class WorkingScheduleFlexibility < ActiveRecord::Migration[5.0]
  def change
    add_column :working_schedules, :flexibility, :integer, null: false, default: 0
  end
end
