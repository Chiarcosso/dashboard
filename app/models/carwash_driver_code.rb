class CarwashDriverCode < ApplicationRecord
  include BarcodeUtility
  require 'barby/barcode/code_128'
  require 'barby/outputter/cairo_outputter'

  belongs_to :person

  scope :findByCode, ->(code) { where(:code => code) }
  scope :findByPerson, ->(person) { where(:person => person) }
  # scope :order_person, -> { joins(:person).order('people.surname,people.name') }

  def self.createUnique person
    if CarwashDriverCode.findByPerson(person).first.nil?
      code = 'A'+SecureRandom.hex(2).upcase
      while !CarwashDriverCode.where(code: code).empty?
        code = 'A'+SecureRandom.hex(2).upcase
      end
      CarwashDriverCode.create(code: code, person: person)
    end
  end

  def to_s
    self.code
  end

  def print_owner
    self.person.complete_name
  end

  def generate_barcode
    @blob = Barby::CairoOutputter.new(Barby::Code128B.new(self.code)).to_png #Raw PNG data
    File.write("tmp/cw-code-temp.png", @blob)
  end

  def regenerate
    self.update(code: 'A'+SecureRandom.hex(2).upcase)
  end

end
