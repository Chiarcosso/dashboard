class CreateCompanyGroups < ActiveRecord::Migration[5.0]
  def change
    unless table_exists? :company_groups
      create_table :company_groups do |t|
        t.string :name, null: false
        t.text :notes
      end
    end

    add_column :companies, :company_group_id, :integer, foreign_key: :company_groups, null: true, index: true unless column_exists? :companies, :company_group_id

  end
end
