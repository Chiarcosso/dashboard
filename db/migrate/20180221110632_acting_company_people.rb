class ActingCompanyPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :company_people, :acting, :bool, index: true, null: false, default: true unless column_exists? :company_people, :acting
    add_index :company_people, [:person_id,:company_id,:company_relation_id], unique: true, name: :company_people_unique unless index_exists? :company_people, [:person_id,:company_id,:company_relation_id], name: :company_people_unique
  end
end
