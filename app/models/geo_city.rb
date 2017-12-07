class GeoCity < ApplicationRecord
  resourcify

  belongs_to :geo_province
  has_one :geo_state, through: :geo_province

  scope :filter, -> (search) { where('geo_cities.name like ?', "%search%") }

end
