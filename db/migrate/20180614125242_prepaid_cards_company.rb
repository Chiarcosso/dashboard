class PrepaidCardsCompany < ActiveRecord::Migration[5.0]
  def change
    add_reference :prepaid_cards, :company, null: false, index: true, foreign_key: true unless column_exists? :prepaid_cards, :company_id
  end
end
