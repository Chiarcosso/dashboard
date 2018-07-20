class LeaveCodeDescriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :leave_codes, :description, :string unless column_exists? :leave_codes, :description
    remove_index :leave_codes, :code if index_exists? :leave_codes, :code
    add_index :leave_codes, :code, unique: true
    # change_column :leave_codes, :code, :string, null: false, index: true, unique: true
  end
end
