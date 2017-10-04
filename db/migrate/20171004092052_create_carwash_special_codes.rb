class CreateCarwashSpecialCodes < ActiveRecord::Migration[5.0]
  def change
    create_table :carwash_special_codes do |t|
      t.string :label, null: false, unique: true
      t.string :code, null: false, unique:true
      t.integer :carwash_code, null: false, default: 0

      t.timestamps
    end
  end
end
