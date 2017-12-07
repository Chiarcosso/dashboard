class CreateArticleCompatibilities < ActiveRecord::Migration[5.0]
  def change
    unless table_exists? :article_compatibility
      create_table :article_compatibilities do |t|
        t.references :article, foreign_key: true, null: false
        t.integer :original_article_id, foreign_key: :articles, null: false, index: true

        t.timestamps
      end
    end
  end
end
