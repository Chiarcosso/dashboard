class Order < ApplicationRecord
  resourcify

  belongs_to :createdBy, class_name: :user
  has_and_belongs_to_many :transportDocument

end
