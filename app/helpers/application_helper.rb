module ApplicationHelper
  include BarcodeUtility

  def calling_methods
    return caller.select{ |c| /.*_(controller)\..*/ =~ c }.map{ |c| {controller: c.match(/.*\/(.*?)_controller.*/)[1], method: c.match(/.*?in `(.*?)'/)[1] }}
  end
  
  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def generateBarcode(barcode,type = 'Code39',filename = nil)
    if filename.nil?
      filename = barcode
    end
    if bc = checkBarcode(barcode)
      @blob = Barby::CairoOutputter.new(bc).to_png() #Raw PNG data
      File.write("public/images/#{filename}.png", @blob)
    end
  end

end
