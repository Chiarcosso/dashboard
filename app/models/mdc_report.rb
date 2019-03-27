class MdcReport < ApplicationRecord
  belongs_to :vehicle
  belongs_to :mdc_user
  has_many :images, class_name: 'MdcReportImage'
end
