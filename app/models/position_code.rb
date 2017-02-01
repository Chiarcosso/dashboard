class PositionCode < ApplicationRecord
  resourcify

  def self.findByCode(code)
    tokens = code.split('-')
    PositionCode.where(:floor => tokens[0][1..-1].to_i, :row => tokens[1][1..-1].to_i, :level => tokens[2][1..-1].to_i, :sector => tokens[3][1..-1].to_i, :section => tokens[4][1..-1].to_i).first
  end

  def code
    'P'+self.floor.to_s+'-C'+self.row.to_s+'-L'+self.level.to_s+'-X'+self.sector.to_s+'-Y'+self.section.to_s
  end

  def printLabel
    label = Zebra::Epl::Label.new(
      :width         => 385,
      :length        => 180,
      :print_speed   => 3,
      :print_density => 6
    )

    barcode = Zebra::Epl::Barcode.new(
      :data                      => self.code,
      :position                  => [30, 20],
      :height                    => 100,
      :print_human_readable_code => true,
      :narrow_bar_width          => 2,
      :wide_bar_width            => 4,
      :type                      => Zebra::Epl::BarcodeType::CODE_128_AUTO
    )
    label << barcode
    print_job = Zebra::PrintJob.new "zebra"
    print_job.print label
  end

end
