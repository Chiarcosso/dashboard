class ExpectedHalfHours < ActiveRecord::Migration[5.0]
  def change
    change_column :working_schedules, :expected_hours, :float, null: false, default: 9
    WorkingSchedule.all.each do |ws|
      ws.update(expected_hours: ws.duration_agreement/3600)
    end
  end
end
