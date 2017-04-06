class ItemRelation < ApplicationRecord
  resourcify
  belongs_to :office
  belongs_to :vehicle
  belongs_to :person
  belongs_to :worksheet
  belongs_to :item


  scope :available, -> { where('item_relations.office_id' => nil).where('item_relations.vehicle_id' => nil).where('item_relations.person_id' => nil).where('item_relations.worksheet_id' => nil) }
  # scope :available, -> { group(:item_id,:id).order(:updated_at) }

end
