module BarcodeUtility
require 'barby/barcode/code_39'
require 'barby/barcode/code_93'
require 'barby/barcode/code_128'
require 'barby/barcode/gs1_128'
require 'barby/barcode/ean_13'
require 'barby/barcode/ean_8'

  def checkBarcode(barcode)
    @bc = false
    begin
      @bc = Barby::Code128.new(barcode.to_s.encode(Encoding::ASCII),true)
    rescue
      begin
        @bc = Barby::Code39.new(barcode.to_s.encode(Encoding::ASCII),true)
      rescue
        begin
          @bc = Barby::Code93.new(barcode.to_s.encode(Encoding::ASCII),true)
        rescue
          begin
            @bc = Barby::EAN128.new(barcode,'C',21)
          rescue
            if barcode[0..-2].size == 12
              @bc = Barby::EAN13.new(barcode[0..-2])
            elsif barcode[0..-2].size == 7
              @bc = Barby::EAN8.new(barcode[0..-2])
            end
          end
        end
      end
    end
    return @bc

    # begin
    #   case type
    #     when 'Code128'
    #       Barby::Code128.new(barcode.to_s.encode(Encoding::ASCII),true)
    #     when 'Code39'
    #       Barby::Code39.new(barcode.to_s.encode(Encoding::ASCII),true)
    #     when 'Code93'
    #       Barby::Code93.new(barcode.to_s.encode(Encoding::ASCII),true)
    #     when 'EAN128'
    #       Barby::EAN128.new(barcode,'C',21)
    #     when "EAN"
    #       if barcode[0..-2].size == 12
    #         Barby::EAN13.new(barcode[0..-2])
    #       elsif barcode[0..-2].size == 7
    #         Barby::EAN8.new(barcode[0..-2])
    #       else
    #         return false
    #       end
    #   end
    # rescue
    #   return false
    # end
  end



end
