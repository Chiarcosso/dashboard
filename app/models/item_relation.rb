class ItemRelation < ApplicationRecord
  resourcify
  belongs_to :office
  belongs_to :vehicle
  belongs_to :person
  belongs_to :item
  
end
