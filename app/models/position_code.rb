class PositionCode < ApplicationRecord
  resourcify

  enum row: ['#','A','B','C','D','E','F','G','H','I','J','K','L']
  enum section: ['@','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z']

  def self.findByCode(code)
    begin
      tokens = code.split(' ')
      floor = tokens[0][1..-1].to_i
      row = rows[tokens[1][0..0]]
      sector = tokens[1][1..-1].to_i
      tok = tokens[2].split('-')
      level = tok[0].to_i
      section = sections[tok[1]]
      PositionCode.where(:floor => floor, :row => row, :level => level, :sector => sector, :section => section).first
    rescue
      nil
    end
  end

  def self.getQueryFromCode code
    begin
      tokens = code.split(' ')
      floor = tokens[0][1..-1].to_i
      row = rows[tokens[1][0..0]]
      sector = tokens[1][1..-1].to_i
      tok = tokens[2].split('-')
      level = tok[0].to_i
      section = sections[tok[1]]
      # PositionCode.where(:floor => floor, :row => row, :level => level, :sector => sector, :section => section).first
      "position_codes.floor = #{floor} AND position_codes.row = #{row} AND position_codes.level = #{level} AND position_codes.sector = #{sector} AND position_codes.section = #{section}"
    rescue
      'NULL'
    end
  end

  def code
    'P'+self.floor.to_s+' '+self.row+self.sector.to_s+' '+self.level.to_s+'-'+self.section.to_s
  end

  def printLabel
    label = Zebra::Epl::Label.new(
      :width         => 385,
      :length        => 180,
      :print_speed   => 1,
      :print_density => 15
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
      :position                  => [10, 45],
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
