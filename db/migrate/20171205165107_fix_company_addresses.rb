class FixCompanyAddresses < ActiveRecord::Migration[5.0]
  def change
    change_column :company_addresses, :number, :string
    add_index :company_addresses, [:street,:number,:internal,:zip,:geo_city_id], unique: true, name: 'company_address_unique' unless index_exists? :company_addresses, name: 'company_address_unique'
  end
end
