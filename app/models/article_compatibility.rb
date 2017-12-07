class ArticleCompatibility < ApplicationRecord
  resourcify

  belongs_to :article
  belongs_to :original_article, foreign_key: :original_article_id, class_name: :article
end
