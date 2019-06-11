class MdcReportImage < ApplicationRecord
  belongs_to :mdc_report

  def complete_url
    "http://#{ENV['RAILS_IIS_URL']}#{self.url}"
  end
end
