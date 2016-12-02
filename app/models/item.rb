class Item < ApplicationRecord
  resourcify

  belongs_to :article
  belongs_to :transportDocument

  

end
