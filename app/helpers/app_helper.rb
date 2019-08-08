module AppHelper

  def calling_methods
    return caller.select{ |c| /.*_(controller)\..*/ =~ c }.map{ |c| {controller: c.match(/.*\/(.*?)_controller.*/)[1], method: c.match(/.*?in `(.*?)'/)[1] }}
  end

end
