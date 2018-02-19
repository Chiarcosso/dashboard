class GeoController < ApplicationController

    def geo_city_autocomplete
      unless params[:search].nil? or params[:search] == ''
        search = params.require(:search).tr(' ','%')
        render :json => GeoCity.find_by_sql("select  'geo_city' as field, 'GeoCity' as model, gc.id as geo_city_id, concat(gc.name,', ',gc.zip,' (',gp.code,')') as label from geo_cities gc inner join geo_provinces gp on gp.id = gc.geo_province_id where gc.name like '%#{search}%' or gc.zip like '%#{search}%' limit 10")
      end
    end

    def geo_state_autocomplete
      unless params[:search].nil? or params[:search] == ''
        # array = GeoState.filter(params.require(:search))
        search = params.require(:search).tr(' ','%')
        render :json => GeoState.find_by_sql("select 'geo_state' as field,  'GeoState' as model, gs.id as geo_state_id, concat(gs.name,', ',gs.code) as label from geo_states gs where gs.name like '%#{search}%' or gs.code like '%#{search}%' limit 10")
      end
    end

    def geo_language_autocomplete
      unless params[:search].nil? or params[:search] == ''
        # array = Language.filter(params.require(:search))
        search = params.require(:search).tr(' ','%')
        array = Language.find_by_sql("select 'language' as field, 'Language' as model, l.id as language_id, l.name as label from languages l where l.name like '%#{search}%' limit 10")
        render :json => array #GeoCity.find_by_sql("select geo_cities.id as id, geo_cities.name as name, geo_province.name as province, geo_province.code as province_code, geo_state.name as state, geo_state.code as state_code from geo_cities inner join geo_provinces on geo_cities.geo_province_id = geo_province.id inner join geo_states on geo_province.geo_state_id = geo_state.id")
      end
    end

    def geo_province_autocomplete
      unless params[:search].nil? or params[:search] == ''
        search = params.require(:search).tr(' ','%')
        render :json => GeoProvince.find_by_sql("select 'geo_province' as field,  'GeoProvince' as model, gp.id as geo_province_id, concat(gp.name,', ',gp.code,' (',gs.code,')') as label from geo_provinces gp inner join geo_states gs on gs.id = gp.geo_state_id where gp.name like '%#{search}%' or gp.code like '%#{search}%' limit 10")
      end
    end

    def geo_locality_autocomplete
      unless params[:search].nil? or params[:search] == ''
        search = params.require(:search).tr(' ','%')
        render :json => GeoLocality.find_by_sql("select  'geo_locality' as field, 'GeoLocality' as model, gl.id geo_locality_id, concat(gl.name,', ',gl.zip,' (',gc.name,')') as label from geo_localities gl inner join geo_cities gc on gc.id = gl.geo_city_id where gl.name like '%#{search}%' or gl.zip like '%#{search}%' or gc.name like '%#{search}%' or gc.zip like '%#{search}%' limit 10")
      end
    end

    def popup
      render :js, :partial => 'geo/popup'
    end

    def new_record
      model = params.require(:model).constantize
      p = params.require(:data).permit([:name, :code, :language, :geo_state, :zip, :geo_province, :geo_city]).to_h
      p[:language] = Language.find(p[:language].to_i) unless p[:language].nil?
      p[:geo_state] = GeoState.find(p[:geo_state].to_i) unless p[:geo_state].nil?
      p[:geo_province] = GeoProvince.find(p[:geo_province].to_i) unless p[:geo_province].nil?
      p[:geo_city] = GeoCity.find(p[:geo_city].to_i) unless p[:geo_city].nil?
      model.create(p) unless model.all.include? model.new(p)
    end

    def geo_autocomplete
      if params[:search].nil? or params[:search] == ''
        render :json => {}
      else
        search = params.require(:search).tr(' ','%')
        cities = GeoCity.find_by_sql("select 'city' as field, 'GeoCity' as model, gc.id as geo_city_id, gc.name as city_name, '' as locality_name, gc.zip, gp.code as province_code, gs.name as state_name, concat(gc.name,', ',gc.zip,' (',gp.code,')') as label from geo_cities gc inner join geo_provinces gp on gp.id = gc.geo_province_id inner join geo_states gs on gp.geo_state_id = gs.id where gc.name like '%#{search}%' or gc.zip like '%#{search}%'")
        localities = GeoLocality.find_by_sql("select 'city' as field, 'GeoLocality' as model, gl.id as geo_locality, gc.id as geo_city, gc.id as geo_city_id, gl.name as locality_name, gc.name as city_name, gp.code as province_code, (case when gl.zip is null or gl.zip = '' then gc.zip else gl.zip end) as zip, gs.name as state_name, concat(gl.name,', ',(case when gl.zip is null or gl.zip = '' then gc.zip else gl.zip end),' (',gc.name,')') as label from geo_localities gl inner join geo_cities gc on gc.id = gl.geo_city_id inner join geo_provinces gp on gp.id = gc.geo_province_id inner join geo_states gs on gp.geo_state_id = gs.id where gl.name like '%#{search}%' or gl.zip like '%#{search}%' or gc.name like '%#{search}%' or gc.zip like '%#{search}%'")
        render :json => (cities + localities).take(10)
      end

    end
end
