class CreateWorkshopBrands < ActiveRecord::Migration[5.0]
  def change
    unless table_exists? :workshop_brands
      create_table :workshop_brands do |t|
        
        t.integer :workshop_id, foreign_key: :company_addresses, null: false, index: true
        t.integer :brand_id, foreign_key: :companies, null: false, index: true

        t.timestamps
      end
    end
  end
end
