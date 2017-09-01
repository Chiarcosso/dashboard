class CarwashVehicleCode < ApplicationRecord
  include BarcodeUtility
  require 'barby/barcode/code_128'
  require 'barby/outputter/cairo_outputter'

  belongs_to :vehicle
  has_many :vehicle_informations, :through => :vehicle

  scope :findByCode, ->(code) { where(:code => code) }
  scope :order_plate, -> { joins(:vehicle_informations).where('vehicle_informations.information_type = ?',VehicleInformation.types['Targa']).order('vehicle_informations.information') }

  def regenerate
    self.update(code: 'M'+SecureRandom.hex(2).upcase)
  end

  def print_owner
    self.vehicle.plate
  end

  def generate_barcode
    @blob = Barby::CairoOutputter.new(Barby::Code128B.new(self.code)).to_png #Raw PNG data
    File.write("tmp/cw-code-temp.png", @blob)
  end

  def print
    label = Zebra::Epl::Label.new(
      :width         => 385,
      :length        => 180,
      :print_speed   => 3,
      :print_density => 9
    )

    barcode = Zebra::Epl::Barcode.new(
      :data                      => self.code,
      :position                  => [10, 60],
      :height                    => 110,
      :print_human_readable_code => false,
      :narrow_bar_width          => 3,
      :wide_bar_width            => 6,
      :type                      => Zebra::Epl::BarcodeType::CODE_128_AUTO
    )
    label << barcode
    text  = Zebra::Epl::Text.new :data => self.vehicle.plate, :position => [10, 10], :font => Zebra::Epl::Font::SIZE_4
    label << text
    print_job = Zebra::PrintJob.new "zebra"
    print_job.print label
  end
end
