class ChangeArticles < ActiveRecord::Migration[5.0]
  def change
    change_column :articles, :containedAmount, :decimal, :precision => 12, :scale => 3
    change_column :articles, :minimalReserve, :decimal, :precision => 12, :scale => 3
  end
end
