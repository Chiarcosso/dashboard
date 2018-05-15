class RemVcsWorksheetsColumn < ActiveRecord::Migration[5.0]
  def change
    remove_reference :vehicle_check_sessions, :worksheets if column_exists? :vehicle_check_sessions, :worksheets_id
  end
end
