class MdcReportImage < ApplicationRecord
  belongs_to :mdc_report

  def complete_url
    url = self.url
    unless /https?:\/\/.*/ =~ url
      url = "http://#{ENV['RAILS_IIS_URL']}/#{url}"
    end
    return URI.escape(url)
  end
end
