class ChangePrepaidCardsPin < ActiveRecord::Migration[5.0]
  def change
    change_column :prepaid_cards, :pin, :string, null: false
  end
end
