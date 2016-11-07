class CreateArticleCategoriesRelation < ActiveRecord::Migration[5.0]
  def change
    create_table :article_categories_relations do |t|
      t.integer :parent_id
      t.integer :child_id
    end
  end
end
