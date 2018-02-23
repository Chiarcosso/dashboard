class CarwashUsagesPersonNull < ActiveRecord::Migration[5.0]
  def change
    change_column :carwash_usages, :person_id, :integer, null: true
  end
end
