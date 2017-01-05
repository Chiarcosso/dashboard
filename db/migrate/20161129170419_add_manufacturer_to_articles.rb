class AddManufacturerToArticles < ActiveRecord::Migration[5.0]
  def change
    # remove_column(:articles, :manufacturer_id)
    add_reference(:articles, :manufacturer, foreign_key: {to_table: :companies})
  end
end
