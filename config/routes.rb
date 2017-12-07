Rails.application.routes.draw do
  resources :vehicle_typologies
  # resources :equipment do
  #
  # end
  resources :equipment_groups
  resources :company_relations
  resources :vehicle_informations
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

  post   '/sendfare', to: 'ws#update_fares', as: :update_fares
  # get    '/autocomplete/:model/:search', to: 'companies#autocomplete', as: :ac_companies
  post   '/roles/', to: 'roles#create', as: :roles

  post   '/users/:id/roles/:role', to: 'users#add_role'
  delete '/users/:id/roles/:role', to: 'users#rem_role'

  get    '/storage', to: 'storage#home', as: :storage
  get    '/storage_reception', to: 'storage#reception', as: :storage_reception
  # post   '/storage_reception', to: 'storage#reception', as: :storage_reception
  get    '/storage_output', to: 'storage#output', as: :storage_output
  get    '/storage_management', to: 'storage#management', as: :storage_management

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

  get    '/output/:destination', to: 'orders#output', as: :output
  post   '/output/ws/:code', to: 'orders#edit_output', as: :edit_output
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
  post   '/worksheet/hours', to: 'worksheets#set_hours', as: :worksheet_hours
  post   "/worksheet/toogle_closure", to: 'orders#toggle_worksheet_closure', as: :worksheet_closure_toggle

  get '/equipment', to: 'equipment#index', as: :equipment
  get '/equipment_home', to: 'equipment#home', as: :equipment_home

  get  '/mdc/transport_documents/:status', to: 'ws#index', as: :mdc_transport_documents
  post 'mdc/close_fare', to: 'ws#close_fare', as: :mdc_close_fare
  post 'mdc/download_ws_pdf', to: 'ws#print_pdf', as: :mdc_download_ws_pdf
  get  '/mdc/codes', to: 'ws#codes', as: :mdc_codes
  post '/mdc/new_code', to: 'ws#create_user', as: :new_mdc_code
  post '/mdc/update_code', to: 'ws#update_user', as: :update_mdc_code
  # get '/equipment_groups', to: 'equipment_groups#index', as: :equipment_groups

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

  get '/carwash/', to: 'carwash#index', as: :carwash

  post '/geo/geo_city_autocomplete', to: 'geo#geo_city_autocomplete', as: :custom_geo_city_autocomplete
  post '/geo/geo_province_autocomplete', to: 'geo#geo_province_autocomplete', as: :custom_geo_province_autocomplete
  post '/geo/geo_state_autocomplete', to: 'geo#geo_state_autocomplete', as: :custom_geo_state_autocomplete
  post '/geo/geo_language_autocomplete', to: 'geo#geo_language_autocomplete', as: :custom_geo_language_autocomplete
  post '/geo/geo_locality_autocomplete', to: 'geo#geo_locality_autocomplete', as: :custom_geo_locality_autocomplete
  post '/geo/geo_autocomplete', to: 'geo#geo_autocomplete', as: :custom_geo_autocomplete
  get '/geo/geo_popup/', to: 'geo#popup', as: :geo_popup
  post '/geo/new/', to: 'geo#new_record', as: :new_geo_record
  # post '/geo/new_language', to: 'geo#new_language', as: :new_language
  # post '/geo/new_state', to: 'geo#new_state', as: :new_state
  # post '/geo/new_province', to: 'geo#new_province', as: :new_province
  # post '/geo/new_city', to: 'geo#new_city', as: :new_city
  # post '/geo/new_locality', to: 'geo#new_locality', as: :new_locality

  get '/companies/edit_address_popup/:address_id', to: 'companies#edit_address_popup', as: :edit_address_popup
  post '/companies/update_address/', to: 'companies#update_address_popup', as: :update_address
  delete '/companies/:id/:address_id/del_address', to: 'companies#del_address', as: :delete_company_address
  post '/companies/:id/add_address', to: 'companies#add_address', as: :add_company_address
  post '/companies/:id/add_phone', to: 'companies#add_phone', as: :add_company_phone
end
