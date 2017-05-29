class CreateEquipmentArticles < ActiveRecord::Migration[5.0]
  def change
    create_table :equipment_articles do |t|
      t.references :equipment, foreign_key: true, null: false
      t.references :article, foreign_key: true, null: false
      t.string :size

      t.timestamps
    end
  end
end
