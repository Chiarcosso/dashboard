class FixContactsAddresses < ActiveRecord::Migration[5.0]
  def change
    add_reference :company_phone_numbers, :company_address, null: true, index: true, foreign_key: true
    add_reference :company_mail_addresses, :company_address, null: true, index: true, foreign_key: true
  end
end
