class CreateCompanyPeople < ActiveRecord::Migration[5.0]
  def change
    create_table :companies_people do |t|
      t.references :person, foreign_key: true
      t.references :company, foreign_key: true
      t.references :company_relation, foreign_key: true

      t.timestamps
    end
  end
end
