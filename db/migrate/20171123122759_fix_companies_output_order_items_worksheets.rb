class FixCompaniesOutputOrderItemsWorksheets < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :workshop, :boolean, null: false, default: false, index: true unless column_exists? :companies, :workshop
    add_column :companies, :client, :boolean, null: false, default: false, index: true unless column_exists? :companies, :client
    add_column :companies, :supplier, :boolean, null: false, default: false, index: true unless column_exists? :companies, :supplier
    add_column :companies, :manufacturer, :boolean, null: false, default: false, index: true unless column_exists? :companies, :manufacturer
    add_column :companies, :transporter, :boolean, null: false, default: false, index: true unless column_exists? :companies, :transporter

    add_column :companies, :main_company_address_id, :integer unless column_exists? :companies, :main_company_address_id
    add_foreign_key :companies, :company_addresses, column: :main_company_address_id

    add_column :companies, :main_mail_address_id, :integer unless column_exists? :companies, :main_mail_address_id
    add_foreign_key :companies, :company_mail_addresses, column: :main_mail_address_id

    add_column :companies, :main_phone_number_id, :integer unless column_exists? :companies, :main_phone_number_id
    add_foreign_key :companies, :company_phone_numbers, column: :main_phone_number_id

    add_column :companies, :pec_mail_address_id, :integer unless column_exists? :companies, :pec_mail_address_id
    add_foreign_key :companies, :company_mail_addresses, column: :pec_mail_address_id

    add_column :company_addresses, :workshop, :boolean, null: false, default: false, index: true unless column_exists? :company_addresses, :workshop
    add_column :company_addresses, :loading_facility, :boolean, null: false, default: false, index: true unless column_exists? :company_addresses, :loading_facility
    add_column :company_addresses, :unloading_facility, :boolean, null: false, default: false, index: true unless column_exists? :company_addresses, :unloading_facility
    add_foreign_key :output_order_items, :items
    add_foreign_key :output_order_items, :output_orders
  end
end
