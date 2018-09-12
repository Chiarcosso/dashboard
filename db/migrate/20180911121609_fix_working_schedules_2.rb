class FixWorkingSchedules2 < ActiveRecord::Migration[5.0]
  def change
    rename_column :working_schedules, :contract_from, :contract_from_s
    rename_column :working_schedules, :contract_to, :contract_to_s
    rename_column :working_schedules, :agreement_from, :agreement_from_s
    rename_column :working_schedules, :agreement_to, :agreement_to_s
  end
end
