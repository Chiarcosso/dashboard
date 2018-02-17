class VehicleInformation < ApplicationRecord
  resourcify

  belongs_to :vehicle
  belongs_to :vehicle_information_type
  # enum type: ['Targa','N. di telaio']

  def complete_information
    "#{self.vehicle_information_type.name}: #{self.get_information}"
  end
  def self.oldest(type,vehicle)
    VehicleInformation.where(vehicle_information_type: type, vehicle: vehicle).order(date: :asc).first
  end

  def self.latest(type,vehicle)
    VehicleInformation.where(vehicle_information_type: type, vehicle: vehicle).order(date: :desc).first
  end

  def next
    unless self.date.nil?
      infos = VehicleInformation.where(vehicle_information_type: self.vehicle_information_type, vehicle: self.vehicle).where("date >= '#{self.date}' ").where("id <> #{self.id}").order(date: :asc).limit(1)

      if infos.size == 1
        infos[0]
      else
        nil
      end
    end
  end

  def date_to
    self.next.date - 1 unless self.next.nil?
  end

  def history
    infos = VehicleInformation.where(vehicle_information_type: self.vehicle_information_type, vehicle: self.vehicle).where("id <> #{self.id}").order(date: :desc)
  end

  def get_information
    if self.information.nil?
      return nil
    else
      begin
        case self.vehicle_information_type.data_type
        when 'Data'
          return Date.parse self.information
        when 'Numero intero'
          return self.information.to_i
        when 'Numero decimale'
          return self.information.to_f
        else
          return self.information
        end
      rescue Exception => e
        return "(Errore) #{self.information}. #{e.message}"
      end
    end
  end

  def information_label
    begin
    return '(vuoto)' if self.information == '' or self.information.nil?
    case self.vehicle_information_type.data_type
    when 'Data'
      return self.get_information.strftime("%d/%m/%Y")
    else
      return self.get_information
    end
  rescue Exception => e
      return "(errore) #{self.information}. \n\n#{e.message}"
    end
  end

  def self.find_by_information(information,type,vehicle)
    VehicleInformation.where(information: information, vehicle_information_type: type, vehicle: vehicle).order(:date).first
  end

end
