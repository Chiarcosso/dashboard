class WorkingScheduleAgreement < ActiveRecord::Migration[5.0]
  def change
    add_column :working_schedules, :agreement, :boolean, null: false, default: true, index: true
  end
end
