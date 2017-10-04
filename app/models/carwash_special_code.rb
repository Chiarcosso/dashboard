class CarwashSpecialCode < ApplicationRecord
  include BarcodeUtility
  require 'barby/barcode/code_128'
  require 'barby/outputter/cairo_outputter'

  belongs_to :person

  scope :findByCode, ->(code) { where(:code => code) }

  def generate_barcode
    @blob = Barby::CairoOutputter.new(Barby::Code128B.new(self.code)).to_png #Raw PNG data
    File.write("tmp/cw-code-temp.png", @blob)
  end

  def regenerate
    self.update(code: 'S'+SecureRandom.hex(2).upcase)
  end
end
