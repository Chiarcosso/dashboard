class CreateCompanies < ActiveRecord::Migration[5.0]
  def change
    create_table :companies do |t|
      t.string :name, limit: 255
      t.string :vat_number, limit: 17
      t.string :ssn, limit: 30

      t.timestamps
    end
  end
end
