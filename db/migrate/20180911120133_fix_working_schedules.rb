class FixWorkingSchedules < ActiveRecord::Migration[5.0]
  def change
    change_column :working_schedules, :agreement_from, :string, null: false
    change_column :working_schedules, :agreement_to, :string, null: false
    change_column :working_schedules, :contract_from, :string, null: false
    change_column :working_schedules, :contract_to, :string, null: false
  end
end
