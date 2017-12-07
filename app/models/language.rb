class Language < ApplicationRecord
  resourcify

  scope :filter, -> (search) { where('name like ?', "%#{search}%") }
end
