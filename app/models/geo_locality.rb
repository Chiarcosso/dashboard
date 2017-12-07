class GeoLocality < ApplicationRecord
  resourcify

  belongs_to :geo_city
  has_one :geo_province, through: :geo_city
  has_one :geo_state, through: :geo_province

  scope :filter, -> (search) { where('geo_localities.name like ?', "%search%") }
end
