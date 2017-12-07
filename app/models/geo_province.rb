class GeoProvince < ApplicationRecord
  resourcify

  belongs_to :geo_state

  scope :filter, -> (search) { where('geo_provinces.name like ?', "%search%") }
end
