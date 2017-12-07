class GeoState < ApplicationRecord
  resourcify

  belongs_to :language
  has_many :geo_provinces
  has_many :cities, through: :geo_provinces

  scope :filter, -> (search) { where('geo_states.name like ? or geo_states.code like ?', "%#{search.tr(' ','%')}%","%#{search.tr(' ','%')}%") }
end
