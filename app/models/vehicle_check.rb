class VehicleCheck < ApplicationRecord
  resourcify
  belongs_to :vehicle
  belongs_to :vehicle_type
  belongs_to :vehicle_typology

  def style_by_importance
    ''
  end

  def select_options
    opts = self.options
    if opts.nil?
      ['Nessuna opzione impostata']
    else
      opts.split('//')
    end
  end

  def self.vehicles(checks,dismissed,all_checks = true)

    raise "Lista controlli vuota." if checks.nil? || checks.count < 1
    companies = Company.us

    case dismissed
    when :undismissed then
      dismissed_filter = "vehicles.dismissed = 0"
    when :dismissed then
      dismissed_filter = "vehicles.dismissed = 1"
    else
      dismissed_filter = nil
    end

    if all_checks
      w = Array.new
      w << dismissed_filter unless dismissed_filter.nil?
      w << "property_id in (#{companies.us.map{|c| c.id}.join(',')})"
      if checks.none?{|c| c.vehicle_type_id.nil?}
        w << "vehicles.vehicle_type_id in (select vehicle_checks.vehicle_type_id from vehicle_checks where id in (#{checks.map{|c|c.id}.join(",")}))"
      end
      if checks.none?{|c| c.vehicle_typology_id.nil?}
        w << "vehicles.vehicle_typology_id in (select vehicle_checks.vehicle_typology_id from vehicle_checks where id in (#{checks.map{|c|c.id}.join(",")}))"
      end

      Vehicle.where(w.join(" and "))
    else
      Vehicle.where("#{dismissed_filter} and property_id in (#{companies.us.map{|c| c.id}.join(',')}) and (vehicle_type_id = #{checks.vehicle_type_id} or vehicle_type_id is null)#{checks.vehicle_typology.nil? ? '' : " and vehicle_typology_id = #{checks.vehicle_typology_id}"}")
    end
  end

  def vehicles(all_checks = true)
    companies = Company.us
    if all_checks
      checks = VehicleCheck.where("label = ?",self.label)
      query = <<-QUERY
        (vehicle_type_id in (select vehicle_type_id from vehicle_checks where label = ?)
        or vehicle_type_id is null)
        and
        (vehicle_typology_id in (select vehicle_typology_id from vehicle_checks where label = ?)
        or vehicle_typology_id is null)
        and
        dismissed = 0
        and
        property_id in (#{companies.us.map{|c| c.id}.join(',')})
      QUERY
      Vehicle.where(query,self.label,self.label)
    else
      Vehicle.where("dismissed = 0 and (vehicle_type_id = #{self.vehicle_type_id} or vehicle_type_id is null)#{self.vehicle_typology.nil? ? '' : " and vehicle_typology_id = #{self.vehicle_typology_id}"}")
    end
  end

  def self.last_checks(checks)
    query = <<-QUERY
    select distinct info.information as plate, checks.label as check_name, concat(operators.surname,' ',operators.name) as operator,
      p_checks.time, p_checks.value, p_checks.notes, p_checks.performed
    from vehicles
      inner join (
          select information,vehicle_id from vehicle_informations
          where vehicle_information_type_id = (select id from vehicle_information_types where name = 'Targa')
          and date = (select max(date) from vehicle_informations
                            group by vehicle_id,vehicle_information_type_id
                            having vehicle_information_type_id = (select id from vehicle_information_types where name = 'Targa')
                          )
          ) info on info.vehicle_id = vehicles.id
      inner join (
          select id,label,vehicle_type_id, vehicle_typology_id from vehicle_checks where id in (#{checks.map{|c| c.id}.join(',')})
        ) checks on (checks.vehicle_type_id is null
          #{checks.any?{|c| c.vehicle_type_id != nil} ? " or checks.vehicle_type_id in (#{checks.select{|c| c.vehicle_type_id != nil}.map{|c| c.vehicle_type_id}.join(',')})" : ''})
          and (checks.vehicle_typology_id is null
          #{checks.any?{|c| c.vehicle_typology_id != nil} ? "or vehicles.vehicle_typology_id in (#{checks.select{|c| c.vehicle_typology_id != nil}.map{|c| c.vehicle_typology_id}.join(',')})" : ''})
      left join (
        select * from vehicle_performed_checks
        where time in (select max(time) from vehicle_performed_checks
                          group by vehicle_check_id,time
                          having vehicle_check_id  in (#{checks.map{|c| c.id}.join(',')})
                        )
      ) p_checks on p_checks.vehicle_check_id  in (#{checks.map{|c| c.id}.join(',')}) and p_checks.vehicle_id = vehicles.id
      left join (
        select people.*,users.id as user_id from people
        inner join users on users.person_id = people.id
      ) operators on p_checks.user_id = operators.user_id
    QUERY
    # checks = VehiclePerformedCheck.find_by_sql(query)
    # byebug
    vehicles = self.vehicles
    # checks = VehiclePerformedCheck.group('vehicle_id,vehicle_check').having("vehicle_id in #{vehicles.map{|v| v.id}.join(',')}")
    vehicles
  end
end
