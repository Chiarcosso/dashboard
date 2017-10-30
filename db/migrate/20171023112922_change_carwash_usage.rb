class ChangeCarwashUsage < ActiveRecord::Migration[5.0]
  def change
    add_reference(:carwash_usages, :carwash_special_code, index: true, foreign_key: true, null: true)
  end
end
