class CarwashVehicleCode < ApplicationRecord
  include BarcodeUtility
  require 'barby/barcode/code_128'
  require 'barby/outputter/cairo_outputter'

  belongs_to :vehicle
  has_many :vehicle_informations, :through => :vehicle
  # has_many :carwash_usages_as_first, :foreign_key => 'vehicle_1_id', :class_name => 'CarwashUsage'
  # has_many :carwash_usages_as_second, :foreign_key => 'vehicle_2_id', :class_name => 'CarwashUsage'

  scope :findByCode, ->(code) { where(:code => code) }
  scope :findByVehicle, ->(vehicle) { where(:vehicle => vehicle) }
  scope :order_plate, -> { joins(:vehicle_informations).where('vehicle_informations.vehicle_information_type_id = ?',VehicleInformationType.where(name: 'Targa').first.id).order('vehicle_informations.information') }

  # def last_usage
  #   self.carwash_usages.order(:starting_time => :desc).limit(1).first unless self.carwash_usages.empty?
  # end
  #
  # def carwash_usages
  #   self.carwash_usages_as_first + self.carwash_usages_as_second
  # end

  def to_s
    self.code
  end

  def self.createUnique vehicle
    if CarwashVehicleCode.findByVehicle(vehicle).first.nil?
      code = 'M'+SecureRandom.hex(2).upcase
      while !CarwashVehicleCode.findByCode(code).first.nil?
        code = 'M'+SecureRandom.hex(2).upcase
      end
      CarwashVehicleCode.create(code: code, vehicle: vehicle)
    end
  end

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
      :print_human_readable_code => true,
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
