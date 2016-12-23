class Office < ApplicationRecord
  resourcify

  has_many :representatives
  
end
