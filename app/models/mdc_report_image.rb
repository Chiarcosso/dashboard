class MdcReportImage < ApplicationRecord
  belongs_to :mdc_report

  def complete_url
    url = self.url
    unless /https?:\/\/.*/ =~ url
      url = "http://#{ENV['RAILS_IIS_URL']}/#{ERB::Util.url_encode(url)}"
    end
    return url
  end
end
