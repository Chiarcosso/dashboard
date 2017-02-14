class OrderItem < ApplicationRecord
  belongs_to :output_order
  belongs_to :item
end
