class RenameCompaniesPeople < ActiveRecord::Migration[5.0]
  def change
    rename_table :companies_people, :company_people
  end
end
