class FixGeoCompaniesWorkshops < ActiveRecord::Migration[5.0]
  def change
    change_column :geo_states, :language_id, :integer, foreign_key: :languages, null: false


    add_column :companies, :institution, :boolean, index: true, null: false, default: false, index: true unless column_exists? :companies, :institution
    add_column :companies, :formation_institute, :boolean, index: true, null: false, default: false, index: true unless column_exists? :companies, :formation_institute
    add_column :companies, :parent_company_id, :integer, foreign_key: :companies, null: true, index: true unless column_exists? :companies, :parent_company_id
    # add_foreign_key :companies, :company_mail_addresses, column: :pec_mail_address_id
  end

end
