class AddCarwashType < ActiveRecord::Migration[5.0]
  def change
    add_column(:vehicle_types, :carwash_type, :integer, null: false, default: 0)
  end
end
