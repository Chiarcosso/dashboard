Rails.application.routes.draw do
  resources :external_vehicles
  resources :vehicle_typologies
  resources :vehicle_categories
  resources :vehicle_equipments
  # resources :equipment do
  #
  # end
  resources :equipment_groups
  resources :company_relations
  resources :vehicle_informations
  resources :vehicle_information_types
  resources :position_codes
  resources :vehicles
  resources :vehicle_models
  resources :vehicle_types
  resources :offices
  resources :items do
    get :autocomplete_article_manufacturerCode, :on => :collection
  end
  resources :transport_documents
  resources :companies
  resources :article_categories
  resources :articles do
    get :autocomplete_company_name, :on => :collection
  end
  resources :orders do
    get :autocomplete_vehicle_information_information, :on => :collection
    # get :autocomplete_person_filter, :on => :collection
  end
  resources :people do
    get :autocomplete_company_name, :on => :collection
  end
  resources :codes, except: [:create,:edit,:update,:delete,:show] do
    get :autocomplete_person_surname, :on => :collection
    get :autocomplete_vehicle_information_information, :on => :collection
  end
  resources :ws do
    get :autocomplete_person_company, :on => :collection
  end
  devise_for :users

  delete '/people/delete_role/:id', to: 'people#delete_role', as: :delete_person_role
  post '/people/add_role', to: 'people#add_role', as: :person_add_role

  # devise_scope :user do
  #   root "devise/sessions#new"
  # end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'home#dashboard'

  get   'admin/import_vehicles', to: 'admin#import_vehicles', as: :admin_import_vehicles
  post  'admin/import_vehicles', to: 'admin#import_vehicles', as: :admin_import_vehicles_send
  get   '/admin/queries', to: 'admin#queries', as: :admin_queries
  get   '/admin/manage', to: 'admin#manage', as: :admin_manage
  post   '/admin/manage', to: 'admin#manage', as: :admin_manage_post
  post   '/admin/queries/vehicles', to: 'admin#send_query_vehicles', as: :admin_queries_vehicles

  post   '/admin/upsync_vehicles/:update', to: 'admin#upsync_vehicles', as: :upsync_vehicles
  post   '/admin/upsync_external_vehicles/:update', to: 'admin#upsync_external_vehicles', as: :upsync_external_vehicles
  post   '/admin/upsync_other_vehicles/:update', to: 'admin#upsync_other_vehicles', as: :upsync_other_vehicles
  post   '/admin/upsync_trailers/:update', to: 'admin#upsync_trailers', as: :upsync_trailers
  post   '/admin/upsync_emplyees/:update', to: 'admin#upsync_employees', as: :upsync_employees

  post   '/admin/queries/people', to: 'admin#send_query_people', as: :admin_queries_people
  get    '/admin/soap', to: 'admin#soap', as: :admin_soap
  get    '/admin/vacation', to: 'admin#get_vacation', as: :admin_vacation
  get    '/admin/gear', to: 'admin#get_gear', as: :admin_gear
  get    '/admin/totals', to: 'administration#totals', as: :admin_totals
  get    '/admin/users', to: 'users#index', as: :users_admin
  post   '/admin/users', to: 'users#create', as: :create_user_admin
  get    '/admin/users/new', to: 'users#new', as: :new_user_admin
  get    '/admin/users/:id/edit', to: 'users#edit', as: :edit_user_admin
  get    '/admin/users/:id', to: 'users#show', as: :show_user_admin
  patch  '/admin/users/:id', to: 'users#update', as: :update_user_admin
  put    '/admin/users/:id', to: 'users#update'
  delete '/admin/users/:id', to: 'users#delete', as: :delete_user_admin

  post '/administration/financial_inventory.xls', to: 'administration#financial_inventory', as: :print_financial_inventory
  post '/administration/:company_id/:year/workshop_financial.xls', to: 'administration#workshop_financial', as: :print_workshop_financial


  # get    '/autocomplete/:model/:search', to: 'companies#autocomplete', as: :ac_companies
  post   '/roles/', to: 'roles#create', as: :roles

  post   '/users/:id/roles/:role', to: 'users#add_role'
  delete '/users/:id/roles/:role', to: 'users#rem_role'


  post   '/position_codes/print/:id', to: 'position_codes#print', as: :position_codes_print
  post   '/items/print/:id', to: 'items#print', as: :items_print
  post   '/articles/print/:id', to: 'articles#print', as: :articles_print

  post   '/incomplete_articles', to: 'articles#incomplete', as: :incomplete_articles
  get    '/incomplete_articles', to: 'articles#incomplete', as: :incomplete_articles_get
  get    '/articles/edit/:id/:search', to: 'articles#edit', as: :p_edit_article
  delete '/articles/:id/:search', to: 'articles#destroy', as: :p_delete_article
  post   '/article_categories/manage', to: 'article_categories#manage', as: :manage_article_categories
  post   '/article/categories/', to: 'articles#list_categories', as: :list_article_categories
  post   '/articles/inventory/', to: 'articles#print_inventory', as: :print_inventory
  post   '/articles/reserve/', to: 'articles#print_reserve', as: :print_reserve
  post '/articles/peer_articles_autocomplete/:field', to: 'articles#peer_articles_autocomplete', as: :custom_peer_articles_autocomplete



  get '/carwash/', to: 'carwash#index', as: :carwash

  # get '/codes/', to: 'codes#index', as: :codes
  post '/codes/carwash_driver_code/new', to: 'codes#new_carwash_driver_code', as: :new_carwash_driver_code
  post '/codes/carwash_driver_code/update', to: 'codes#update_carwash_driver_code', as: :update_carwash_driver_code

  post '/codes/carwash_special_code/new', to: 'codes#new_carwash_special_code', as: :new_carwash_special_code
  post '/codes/carwash_special_code/update', to: 'codes#update_carwash_special_code', as: :update_carwash_special_code
  # delete '/codes/carwash_driver_code/:id/delete', to: 'codes#delete_carwash_driver_code', as: :delete_carwash_driver_code
  post '/codes/carwash_vehicle_code/new', to: 'codes#new_carwash_vehicle_code', as: :new_carwash_vehicle_code
  post '/codes/carwash_vehicle_code/update', to: 'codes#update_carwash_vehicle_code', as: :update_carwash_vehicle_code
  get  '/codes/carwash_check/:code', to: 'codes#carwash_check', as: :carwash_check
  get  '/codes/carwash_authorize/:codes', to: 'codes#carwash_authorize', as: :carwash_authorize
  get  '/codes/carwash_close/:sessionid', to: 'codes#carwash_close', as: :carwash_close

  post '/codes/carwash_print/', to: 'codes#carwash_print', as: :carwash_print
  get  '/codes/mdc', to: 'codes#mdc_index'

  post '/companies/new', to: 'companies#new', as: :new_company_search
  post '/companies/edit', to: 'companies#edit', as: :edit_company_search
  post '/companies/vehicle_manufacturers_autocomplete', to: 'companies#vehicle_manufacturer_autocomplete', as: :custom_vehicle_manufacturers_autocomplete
  post '/companies/vehicle_manufacturers_multi_autocomplete', to: 'companies#vehicle_manufacturer_multi_autocomplete', as: :custom_vehicle_manufacturers_multi_autocomplete
  post '/companies/vehicle_property_autocomplete', to: 'companies#vehicle_property_autocomplete', as: :custom_vehicle_property_autocomplete
  get '/companies/edit_address_popup/:address_id', to: 'companies#edit_address_popup', as: :edit_address_popup
  post '/companies/update_address/', to: 'companies#update_address', as: :update_address
  delete '/companies/:id/:address_id/del_address', to: 'companies#del_address', as: :delete_company_address
  post '/companies/:id/add_address', to: 'companies#add_address', as: :add_company_address
  post '/companies/:id/add_phone', to: 'companies#add_phone', as: :add_company_phone

  get '/equipment', to: 'equipment#index', as: :equipment
  get '/equipment_home', to: 'equipment#home', as: :equipment_home
  # get '/equipment_groups', to: 'equipment_groups#index', as: :equipment_groups

  post '/external_vehicles/json_autocomplete_plate/', to: 'external_vehicles#json_autocomplete_plate', as: :external_vehicles_json_autocomplete_plate

  post '/geo/geo_city_autocomplete', to: 'geo#geo_city_autocomplete', as: :custom_geo_city_autocomplete
  post '/geo/geo_province_autocomplete', to: 'geo#geo_province_autocomplete', as: :custom_geo_province_autocomplete
  post '/geo/geo_state_autocomplete', to: 'geo#geo_state_autocomplete', as: :custom_geo_state_autocomplete
  post '/geo/geo_language_autocomplete', to: 'geo#geo_language_autocomplete', as: :custom_geo_language_autocomplete
  post '/geo/geo_locality_autocomplete', to: 'geo#geo_locality_autocomplete', as: :custom_geo_locality_autocomplete
  post '/geo/geo_autocomplete', to: 'geo#geo_autocomplete', as: :custom_geo_autocomplete
  get '/geo/geo_popup/', to: 'geo#popup', as: :geo_popup
  post '/geo/new/', to: 'geo#new_record', as: :new_geo_record

  get    '/items_from_order/:order', to: 'items#from_order', as: :items_from_order
  get    '/items/edit/:id/:search', to: 'items#edit', as: :p_edit_item
  delete '/items/:id/:search',to: 'items#destroy', as: :p_delete_item
  post   '/items_reposition', to: 'items#reposition', as: :items_reposition
  post   '/items_pricing', to: 'items#pricing', as: :items_pricing
  get    '/items/find/:code', to: 'items#find', as: :item_find
  get    '/items/find_free/:code', to: 'items#find_free', as: :item_find_free
  post   '/items/store', to: 'items#store', as: :store_item
  get    '/items_storage_insert', to: 'items#storage_insert', as: :items_storage_insert
  post   '/items_storage_insert', to: 'items#add_item_to_storage', as: :add_item_to_storage
  get    '/items_vehicle_insert', to: 'items#vehicle_insert', as: :items_vehicle_insert
  get    '/items_new_order', to: 'orders#new_order', as: :items_new_order
  post   '/items_new_order', to: 'orders#add_item_to_new_order', as: :add_item_to_new_order

  get  '/mdc/transport_documents/:status', to: 'ws#index', as: :mdc_transport_documents
  post 'mdc/close_fare', to: 'ws#close_fare', as: :mdc_close_fare
  post 'mdc/download_ws_pdf', to: 'ws#print_pdf', as: :mdc_download_ws_pdf
  get  '/mdc/codes', to: 'ws#codes', as: :mdc_codes
  post '/mdc/new_code', to: 'ws#create_user', as: :new_mdc_code
  post '/mdc/update_code', to: 'ws#update_user', as: :update_mdc_code
  post   '/sendfare', to: 'ws#update_fares', as: :update_fares

  get    '/output/:code', to: 'orders#output', as: :output
  post   '/output/ws/:code', to: 'orders#edit_output', as: :edit_output
  post   '/output/ws/', to: 'orders#edit_ws_output', as: :edit_ws_output
  get    '/output/', to: 'orders#index', as: :output_orders
  post   '/output/', to: 'orders#index', as: :output_orders_search
  post   '/output/add_item', to: 'orders#add_item', as: :add_item_to_order
  get    '/output_order/exit/:id', to: 'orders#exit_order', as: :output_order_exit
  post   '/output_order/confirm', to: 'orders#confirm_order', as: :output_order_confirm
  post   '/output_order/:id', to: 'orders#edit_output_order', as: :output_order_edit
  delete '/output_order/:id', to: 'orders#destroy_output_order', as: :output_order_delete
  post   '/output_order/pdf/:id', to: 'orders#print_pdf', as: :output_order_pdf
  post   '/output_order/pdf/module/:id', to: 'orders#print_pdf_module', as: :output_order_pdf_module
  # get    '/output/office', to: 'items#output_office', as: :output_office
  # get    '/output/worksheet', to: 'items#output_worksheet', as: :output_worksheet
  # get    '/output/vehicle', to: 'items#output_vehicle', as: :output_vehicle
  # get    '/output/equipment', to: 'items#output_equipment', as: :output_equipment

  get    '/storage', to: 'storage#home', as: :storage
  get    '/storage_reception', to: 'storage#reception', as: :storage_reception
  # post   '/storage_reception', to: 'storage#reception', as: :storage_reception
  get    '/storage_output', to: 'storage#output', as: :storage_output
  get    '/storage_management', to: 'storage#management', as: :storage_management

  post '/vehicle_models/new', to: 'vehicle_models#new', as: :new_vehicle_model_search
  post '/vehicle_models/edit', to: 'vehicle_models#edit', as: :edit_vehicle_model_search
  post '/vehicle_model/update', to: 'vehicle_models#update', as: :update_vehicle_model
  get  '/vehicle_model/info/:id', to: 'vehicle_models#get_info', as: :info_vehicle_model

  post '/vehicle_type/update', to: 'vehicle_types#update', as: :update_vehicle_type
  post '/vehicle_category/update', to: 'vehicle_categories#update', as: :update_vehicle_category
  post '/vehicle_typology/update', to: 'vehicle_typologies#update', as: :update_vehicle_typology
  post '/vehicle_equipment/update', to: 'vehicle_equipments#update', as: :update_vehicle_equipment
  post '/vehicle_information_types/update', to: 'vehicle_information_types#update', as: :update_vehicle_information_type
  post '/vehicles/new', to: 'vehicles#new', as: :new_vehicle_search
  post '/vehicles/edit', to: 'vehicles#edit', as: :edit_vehicle_search
  post '/vehicles/edit', to: 'vehicles#back', as: :vehicles_back_search
  post '/vehicle/update', to: 'vehicles#update', as: :update_vehicle

  get '/vehicle/assignation', to: 'vehicles#assignation', as: :vehicles_assignation
  post '/vehicle/massive_delete', to: 'vehicles#massive_delete', as: :massive_vehicles_delete
  post '/vehicle/massive_update', to: 'vehicles#massive_update', as: :massive_vehicles_update
  post  '/vehicle/new_plate', to: 'vehicles#new_plate', as: :vehicle_new_plate
  post  '/vehicle/new_chassis', to: 'vehicles#new_chassis', as: :vehicle_new_chassis
  post  '/vehicle/new_information', to: 'vehicles#new_information', as: :vehicle_new_information
  get  '/vehicle/info/:id', to: 'vehicles#get_info', as: :info_vehicle
  get  '/vehicle/info/workshop/:id', to: 'vehicles#get_workshop_info', as: :info_vehicle_workshop
  post '/vehicle/vehicle_information_type_autocomplete/:id', to: 'vehicles#vehicle_information_type_autocomplete', as: :custom_vehicle_information_type_autocomplete
  post '/vehicle/new_information', to: 'vehicles#new_information', as: :new_vehicle_vehicle_information
  post '/vehicle/create_information', to: 'vehicles#create_information', as: :vehicle_create_information
  post  'vehicles/changing_type', to: 'vehicles#change_type', as: :change_vehicle_type
  post  'vehicles/changing_typology', to: 'vehicles#change_typology', as: :change_vehicle_typology
  delete '/vehicle/delete_information/:id', to: 'vehicles#delete_information', as: :delete_vehicle_information

  post   '/vehicle/info_for_workshop', to: 'vehicles#info_for_workshop', as: :info_for_workshop

  get    '/worksheets/', to: 'worksheets#index', as: :worksheets
  post   '/worksheet/hours', to: 'worksheets#set_hours', as: :worksheet_hours
  post   "/worksheet/toogle_closure", to: 'worksheets#toggle_closure', as: :worksheet_closure_toggle
  post   '/worksheet/filter/', to: 'worksheets#filter', as: :worksheet_filter
end
