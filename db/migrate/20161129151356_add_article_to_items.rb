class AddArticleToItems < ActiveRecord::Migration[5.0]
  def change
    change_table :items do |t|
      t.references :article, null: false, foreign_key: true
    end
  end
end
