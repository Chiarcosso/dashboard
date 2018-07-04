class CreateBadges < ActiveRecord::Migration[5.0]
  def change
    create_table :badges do |t|
      t.string :code, null: false, index: true, unique: true

      t.timestamps
    end
    
  end
end
