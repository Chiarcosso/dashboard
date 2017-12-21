class CreateMobileWorkshopItems < ActiveRecord::Migration[5.0]
  def change
    unless table_exists? :mobile_workshop_items
      create_table :mobile_workshop_items do |t|
        t.integer :storage_item_id, null: false
        t.decimal :remaining_quantity, null: false
        t.integer :mobile_workshop_id, null: false

        t.timestamps
      end
    end
    add_foreign_key :mobile_workshop_items, :items, column: :storage_item_id unless foreign_key_exists? :mobile_workshop_items, :original_item_id
    add_foreign_key :mobile_workshop_items, :offices, column: :mobile_workshop_id unless foreign_key_exists? :mobile_workshop_items, :mobile_workshop_id
  end
end
