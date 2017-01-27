class PositionCode < ApplicationRecord
  resourcify

  def generateNext
    self.code
  end

  def printLabel
    label = Zebra::Epl::Label.new(
      :width         => 385,
      :length        => 180,
      :print_speed   => 3,
      :print_density => 6
    )
    # box = Zebra::Epl::Box.new :position => [0, 0], :end_position => [385, 180], :line_thickness => 2
    # label << box
    text  = Zebra::Epl::Text.new :data => self.expiringDate?? 'Sc. '+self.expiringDate.strftime('%d/%m/%Y') : '', :position => [10, 10], :font => Zebra::Epl::Font::SIZE_3
    label << text
    text  = Zebra::Epl::Text.new :data => self.position_code.code, :position => [220, 10], :font => Zebra::Epl::Font::SIZE_2
    label << text
    text  = Zebra::Epl::Text.new :data => self.article.complete_name, :position => [10, 40], :font => Zebra::Epl::Font::SIZE_2
    label << text
    text  = Zebra::Epl::Text.new :data => self.serial.nil?? '' : 'Mat. '+self.serial, :position => [10, 70], :font => Zebra::Epl::Font::SIZE_4
    label << text
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
