class AddExpectedHoursToSchedule < ActiveRecord::Migration[5.0]
  def change
    add_column :working_schedules, :expected_hours, :integer, null: false, default: 9
  end
end
