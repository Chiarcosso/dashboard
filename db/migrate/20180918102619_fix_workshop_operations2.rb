class FixWorkshopOperations2 < ActiveRecord::Migration[5.0]
  def change
    change_column :workshop_operations, :user_id, :integer, null: true
  end
end
