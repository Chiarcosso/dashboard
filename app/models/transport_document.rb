class TransportDocument < ApplicationRecord
  resourcify
  belongs_to :sender, class_name: :company
  belongs_to :receiver, class_name: :company
  belongs_to :vector, class_name: :company
  belongs_to :subvector, class_name: :company
  has_and_belongs_to_many :order

end
