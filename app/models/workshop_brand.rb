class WorkshopBrand < ApplicationRecord
  resourcify

  belongs_to :workshop, foreign_key: :workshop_id, class_name: :company_address
  belongs_to :brand,foreign_key: :brand_id, class_name: :company
end
