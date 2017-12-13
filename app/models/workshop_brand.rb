class WorkshopBrand < ApplicationRecord
  resourcify

  belongs_to :workshop, class_name: 'CompanyAddress'
  belongs_to :brand, class_name: 'Company'
end
