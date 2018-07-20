class EditLeaveCodes < ActiveRecord::Migration[5.0]
  def change
    change_column :leave_codes, :afterhours, :integer, limit: 2, null: false, default: 0
  end
end
