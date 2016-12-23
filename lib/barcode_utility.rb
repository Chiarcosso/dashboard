module BarcodeUtility
require 'barby/barcode/code_39'
# require 'barby/barcode/code_128'
require 'barby/barcode/gs1_128'
require 'barby/barcode/ean_13'
require 'barby/barcode/ean_8'

  def checkBarcode(barcode,type)
    begin
      case type
        when 'Code39'
          Barby::Code39.new(barcode.to_s.encode(Encoding::ASCII),true)
        when 'EAN128'
          Barby::EAN128.new(barcode,'C',21)
        when "EAN"
          if barcode[0..-2].size == 12
            Barby::EAN13.new(barcode[0..-2])
          elsif barcode[0..-2].size == 7
            Barby::EAN8.new(barcode[0..-2])
          else
            return false
          end
      end
    rescue
      return false
    end
  end



end
