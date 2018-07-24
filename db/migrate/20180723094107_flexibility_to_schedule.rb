class FlexibilityToSchedule < ActiveRecord::Migration[5.0]
  def change
    add_column :working_schedules, :start_flexibility, :integer, null: false, default: 0
    add_column :working_schedules, :break_flexibility, :integer, null: false, default: 15
  end
end
