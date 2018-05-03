class FixCheckPerformed < ActiveRecord::Migration[5.0]
  def change
    change_column :vehicle_performed_checks, :performed, :integer, limit: 3
  end
end
