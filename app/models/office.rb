class Office < ApplicationRecord
  resourcify

  has_many :representatives

  scope :filter, ->(search) { where('name like ?',"%#{search}%") }
  
  def complete_name
    self.name
  end
end
