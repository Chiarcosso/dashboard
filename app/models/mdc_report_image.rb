class MdcReportImage < ApplicationRecord
  belongs_to :mdc_report

  def complete_url
    url = self.url
    if /https?:\/\/.*/ =~ url
      return self.url
    else
      return "http://#{ENV['RAILS_IIS_URL']}#{self.url}"
    end
  end
end
