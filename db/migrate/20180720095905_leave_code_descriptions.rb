class LeaveCodeDescriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :leave_codes, :description, :string
    change_column :leave_codes, :code, :string, null: false, index: true, unique: true
  end
end
