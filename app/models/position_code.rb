class PositionCode < ApplicationRecord
  resourcify

  enum row: ['X','A','B','C','D','E','F','G','H','I','J','K','L']
  enum section: ['x','a','b','c','d']

  def self.findByCode(code)
    begin
      tokens = code.split(' ')
      floor = tokens[0][1..-1].to_i
      row = rows[tokens[1][0..0]]
      level = tokens[1][1..-1].to_i
      tok = tokens[2].split('-')
      sector = tok[0].to_i
      section = sections[tok[1]]
      PositionCode.where(:floor => floor, :row => row, :level => level, :sector => sector, :section => section).first
    rescue
      nil
    end
  end

  def code
    'P'+self.floor.to_s+' '+self.row+self.level.to_s+' '+self.sector.to_s+'-'+self.section.to_s
  end

  def printLabel
    label = Zebra::Epl::Label.new(
      :width         => 385,
      :length        => 180,
      :print_speed   => 3,
      :print_density => 6
    )
    if self.description.size > 32
      text  = Zebra::Epl::Text.new :data => self.description[0..31], :position => [10, 10], :font => Zebra::Epl::Font::SIZE_3
      label << text
      text  = Zebra::Epl::Text.new :data => self.description[32..-1], :position => [10, 20], :font => Zebra::Epl::Font::SIZE_3
      label << text
    else
      text  = Zebra::Epl::Text.new :data => self.description, :position => [10, 10], :font => Zebra::Epl::Font::SIZE_3
      label << text
    end
    barcode = Zebra::Epl::Barcode.new(
      :data                      => self.code,
      :position                  => [30, 45],
      :height                    => 90,
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
