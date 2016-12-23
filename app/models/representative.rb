class Representative < ApplicationRecord
  resourcify

  belongs_to :office
  belongs_to :user

end
