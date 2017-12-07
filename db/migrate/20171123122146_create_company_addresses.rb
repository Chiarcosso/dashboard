class CreateCompanyAddresses < ActiveRecord::Migration[5.0]
  def change

    create_table :company_addresses do |t|
      t.references :company, foreign_key: true, null: false, index: true
      t.decimal :geo_position_lat, :precision => 9, :scale => 6
      t.decimal :geo_position_lng, :precision => 9, :scale => 6
      t.string :street, null: false
      t.integer :number, null: false, index: true
      t.string :internal
      t.references :geo_city, foreign_key: true, null: false, index: true
      t.string :zip, null: false
      t.references :geo_locality, foreign_key: true
      t.string :location_qualification, null: false, index: true
      t.boolean :closed, null: false, default: false
      t.string :notes

      t.timestamps
    end
    create_table :company_mail_addresses do |t|
      t.references :company, foreign_key: true, null: false
      t.string :address, null: false
      t.string :address_qualification, null: false, default: 'Sede secondaria'
      t.boolean :pec
      t.string :notes

      t.timestamps
    end
    create_table :company_phone_numbers do |t|
      t.references :company, foreign_key: true, null: false
      t.string :international_prefix, null: false
      t.string :prefix, null: false
      t.string :number
      t.integer :number_type, limit: 1
      t.string :number_qualification, null: false, default: 'Sede secondaria'
      t.string :notes

      t.timestamps
    end
  end
end
