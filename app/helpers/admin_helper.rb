module AdminHelper
  def query_vehicles
    # client = TinyTds::Client.new username: ENV['RAILS_SQL_USER'], password: ENV['RAILS_SQL_PASS'], host: ENV['RAILS_SQL_HOST'], port: ENV['RAILS_SQL_PORT'], database: ENV['RAILS_SQL_DB']
    @altri_mezzi = MssqlReference::upsync_other_vehicles[:array]
    @veicoli = MssqlReference::upsync_vehicles[:array]
    @rimorchi1 = MssqlReference::upsync_trailers[:array]
    @delete_vehicles = Vehicle.free_to_delete - @veicoli - @altri_mezzi - @rimorchi1
    @no_delete_vehicles = Vehicle.not_free_to_delete - @veicoli - @altri_mezzi - @rimorchi1

    # client.execute("select 'Veicoli' as tabella, idveicolo, targa, ditta, marca, modello from veicoli "\
    #             "where marca is not null and marca != '' and modello is not null and modello != '' "\
    #             "order by targa").each do |r|
    #               v = Vehicle.find_by_plate(r['targa'].tr('. *',''))
    #               if v.nil?
    #                 @veicoli << {vehicle: v, data: r, color: '#f99', route: :new}
    #               elsif v.check_properties(r)
    #                 @veicoli << {vehicle: v, data: r, color: '#fff', route: nil}
    #               else
    #                 @veicoli << {vehicle: v, data: r, color: '#99f', route: :edit}
    #               end
    #               @delete_vehicles -= [v] unless v.nil?
    #               @no_delete_vehicles -= [v] unless v.nil?
    #             end
    # @veicoli = @veicoli.select { |r| r[:color] == '#f99' } + @veicoli.select { |r| r[:color] == '#99f' } + @veicoli.select { |r| r[:color] == '#fff' }

    # client.execute("select 'Rimorchi1' as tabella, idrimorchio as idveicolo, targa, ditta, marca, "\
    #             "(case tipo when 'S' then 'Semirimorchio' when 'R' then 'Rimorchio' end) as modello "\
    #             "from rimorchi1 "\
    #             "where marca is not null and marca != '' "\
    #             "order by targa").each do |r|
    #               v = Vehicle.find_by_plate(r['targa'].tr('. *',''))
    #               if v.nil?
    #                 @rimorchi1 << {vehicle: v, data: r, color: '#f99', route: :new}
    #               elsif v.check_properties(r)
    #                 @rimorchi1 << {vehicle: v, data: r, color: '#fff', route: nil}
    #               else
    #                 @rimorchi1 << {vehicle: v, data: r, color: '#99f', route: :edit}
    #               end
    #               @delete_vehicles -= [v] unless v.nil?
    #               @no_delete_vehicles -= [v] unless v.nil?
    #             end
    # # @rimorchi1 = @rimorchi1.select { |r| r[:color] == '#f99' } + @rimorchi1.select { |r| r[:color] == '#99f' } + @rimorchi1.select { |r| r[:color] == '#fff' }
    #
    # client.execute("select 'Altri mezzi' as tabella, convert(int,cod) as idveicolo, targa, ditta, marca, modello "\
    #             "from [Altri mezzi] "\
    #             "where marca is not null and marca != '' and modello is not null and modello != '' "\
    #             "order by targa").each do |r|
    #               v = Vehicle.find_by_plate(r['targa'].tr('. *',''))
    #               if v.nil?
    #                 @altri_mezzi << {vehicle: v, data: r, color: '#f99', route: :new}
    #               elsif v.check_properties(r)
    #                 @altri_mezzi << {vehicle: v, data: r, color: '#fff', route: nil}
    #               else
    #                 @altri_mezzi << {vehicle: v, data: r, color: '#99f', route: :edit}
    #               end
    #               @delete_vehicles -= [v] unless v.nil?
    #               @no_delete_vehicles -= [v] unless v.nil?
    #             end
    # # @altri_mezzi = @altri_mezzi.select { |r| r[:color] == '#f99' } + @altri_mezzi.select { |r| r[:color] == '#99f' } + @altri_mezzi.select { |r| r[:color] == '#fff' }
    #
    # @delete_vehicles.sort_by! {|v| v.plate}
    # @no_delete_vehicles.sort_by! {|v| v.plate}
    # @plate = VehicleInformationType.plate
    # @chassis = VehicleInformationType.chassis
    # @chiarcosso = Company.chiarcosso
    # @transest = Company.transest
    # @equipment = VehicleEquipment.order(:name).to_a
    # @information_types = VehicleInformationType.order(:name).to_a
    # @transporters = Company.where(transporter: true).order(:name).to_a
    # @manufacturers = Company.where(vehicle_manufacturer: true).order(:name).to_a
  end

end
