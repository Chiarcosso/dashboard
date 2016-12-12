class CreateOrderArticles < ActiveRecord::Migration[5.0]
  def change
    create_table :order_articles do |t|
      t.references :order, foreign_key: true
      t.references :article, foreign_key: true
      t.integer :amount

      t.timestamps
    end
  end
end
