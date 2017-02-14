class Office < ApplicationRecord
  resourcify

  has_many :representatives

  def complete_name
    self.name
  end
end
