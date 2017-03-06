class CreateCompanyPeople < ActiveRecord::Migration[5.0]
  def change
    create_table :companies_people do |t|
      t.references :person, index: true, foreign_key: {on_delete: cascade}
      t.references :company, index: true, foreign_key: {on_delete: cascade}
      t.references :company_relation, index: true, foreign_key: {on_delete: cascade}

      t.timestamps
    end
  end
end
