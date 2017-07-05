Rails.application.routes.draw do
  # resources :equipment do
  #
  # end
  resources :equipment_groups
  resources :company_relations
  resources :vehicle_informations
  resources :position_codes
  resources :vehicles
  resources :vehicle_models
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
  end
  resources :people do
    get :autocomplete_company_name, :on => :collection
  end
  devise_for :users

  delete '/people/delete_role/:id', to: 'people#delete_role', as: :delete_person_role
  post '/people/add_role', to: 'people#add_role', as: :person_add_role

  # devise_scope :user do
  #   root "devise/sessions#new"
  # end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'home#dashboard'

  get   '/admin/queries', to: 'admin#queries', as: :admin_queries
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

  get    '/incomplete_articles', to: 'articles#incomplete', as: :incomplete_articles
  get '/articles/edit/:id/:search', to: 'articles#edit', as: :p_edit_article
  post   '/article_categories/manage', to: 'article_categories#manage', as: :manage_article_categories
  post   '/article/categories/', to: 'articles#list_categories', as: :list_article_categories

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
  # get '/equipment_groups', to: 'equipment_groups#index', as: :equipment_groups
end
