class PositionCode < ApplicationRecord
  resourcify

  def code
    'P'+self.floor.to_s+'C'+self.row.to_s+'L'+self.level.to_s+'X'+self.sector.to_s+'Y'+self.section.to_s
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
      :position                  => [30, 120],
      :height                    => 70,
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
