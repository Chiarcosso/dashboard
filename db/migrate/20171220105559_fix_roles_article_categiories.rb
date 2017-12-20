class FixRolesArticleCategiories < ActiveRecord::Migration[5.0]
  def change
    add_index :roles, :name, unique: true unless index_exists? :roles, :name
    add_foreign_key :article_categorizations, :article_categories, column: :article_id unless foreign_key_exists? :article_categorizations, :article_id
  end
end
