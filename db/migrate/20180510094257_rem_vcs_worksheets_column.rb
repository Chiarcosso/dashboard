class RemVcsWorksheetsColumn < ActiveRecord::Migration[5.0]
  def change
    remove_reference :vehicle_check_sessions, :worksheets
  end
end
