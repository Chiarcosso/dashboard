class TransportDocument < ApplicationRecord
  resourcify
  belongs_to :sender, class_name: :Company
  belongs_to :receiver, class_name: :Company
  belongs_to :vector, class_name: :Company
  belongs_to :subvector, class_name: :Company
  has_and_belongs_to_many :order
  has_many :items

end
