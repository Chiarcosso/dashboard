class AddArticleFields < ActiveRecord::Migration[5.0]
  def change
    add_column :articles, :measure_unit, :integer, limit: 3, null: false
  end
end
