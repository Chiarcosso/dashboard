class OutputOrderItem < ApplicationRecord
  resourcify

  belongs_to :item
  belongs_to :output_order
  
end
