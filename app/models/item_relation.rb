class ItemRelation < ApplicationRecord
  resourcify
  belongs_to :office
  belongs_to :vehicle
end
