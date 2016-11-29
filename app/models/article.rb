class Article < ApplicationRecord
  resourcify

  has_and_belongs_to_many :categories, class_name: "ArticleCategory",
                                     join_table: "article_categorizations",
                                     foreign_key: :category_id,
                                     association_foreign_key: :article_id

  has_many :items
  
  scope :incomplete, -> { where(barcode: '') }

  def self.incompleteItems
    Article.all
  end

  def categoriesList
    list = Array.new
    self.categories.each do |cat|
      list << cat.name
    end
    list.join(', ')
  end

  def checkBarcode
    begin
      Barby::EAN13.new(self.barcode[0..-2])
    rescue
      return false
    end
  end

end
