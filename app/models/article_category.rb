class ArticleCategory < ApplicationRecord
  resourcify
  has_ancestry

  scope :main, -> { where ('ancestry IS NULL') }


end
