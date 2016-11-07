class ArticleCategory < ApplicationRecord
  resourcify
  # has_ancestry cache_depth: true, orphan_strategy: :restrict

  # scope :parents, -> { where ('ancestry IS NULL') }

  has_and_belongs_to_many :parentCategories, class_name: "ArticleCategory",
                                     join_table: "article_categories_relations",
                                     foreign_key: :child_id,
                                     association_foreign_key: :parent_id

  has_and_belongs_to_many :childCategories, class_name: "ArticleCategory",
                                      join_table: "article_categories_relations",
                                      foreign_key: :parent_id,
                                      association_foreign_key: :child_id

  # has_many :relations, :foreign_key => "parent_id",
  #     :class_name => "Friendship"
  # has_many :parents, through: => :relation
  # has_many :children, through: => :relation

  def self.roots
    ArticleCategory.all { |ac| ac.parents.empty? }
  end

  def childrenList
    self.childCategories.ids.map(&:to_s).join('-')
  end

end
