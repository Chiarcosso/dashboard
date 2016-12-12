class Order < ApplicationRecord
  resourcify

  belongs_to :createdBy, class_name: :User
  belongs_to :supplier, class_name: :Company
  has_and_belongs_to_many :transport_documents
  has_many :articles, through: :order_articles

  # scope :lastCompany, -> { where(barcode: '') }

end
