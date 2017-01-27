Rails.application.routes.draw do
  resources :vehicles
  resources :vehicle_models
  resources :offices
  resources :orders
  resources :items
  resources :transport_documents
  resources :companies
  resources :article_categories
  resources :articles do
    get :autocomplete_company_name, :on => :collection
  end
  resources :people
  devise_for :users
  # devise_scope :user do
  #   root "devise/sessions#new"
  # end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'home#dashboard'

  get    '/admin/users', to: 'users#index', as: :users_admin
  post   '/admin/users', to: 'users#create', as: :create_user_admin
  get    '/admin/users/new', to: 'users#new', as: :new_user_admin
  get    '/admin/users/:id/edit', to: 'users#edit', as: :edit_user_admin
  get    '/admin/users/:id', to: 'users#show', as: :show_user_admin
  patch  '/admin/users/:id', to: 'users#update', as: :update_user_admin
  put    '/admin/users/:id', to: 'users#update'
  delete '/admin/users/:id', to: 'users#delete', as: :delete_user_admin

  # get    '/autocomplete/:model/:search', to: 'companies#autocomplete', as: :ac_companies


  post   '/users/:id/roles/:role', to: 'users#add_role'
  delete '/users/:id/roles/:role', to: 'users#rem_role'

  get    '/storage', to: 'storage#home', as: :storage
  get    '/storage_reception', to: 'storage#reception', as: :storage_reception
  get    '/storage_output', to: 'storage#output', as: :storage_output
  get    '/storage_management', to: 'storage#management', as: :storage_management

  get    '/incomplete_articles', to: 'articles#incomplete', as: :incomplete_articles
  post   '/article_categories/manage', to: 'article_categories#manage', as: :manage_article_categories
  post   '/article/categories/', to: 'articles#list_categories', as: :list_article_categories

  get    '/items_from_order/:order', to: 'items#from_order', as: :items_from_order

  post   '/items/store', to: 'items#store', as: :store_item
  get    '/items_storage_insert', to: 'items#storage_insert', as: :items_storage_insert
  post   '/items_storage_insert', to: 'items#add_item_to_storage', as: :add_item_to_storage
  get    '/items_vehicle_insert', to: 'items#vehicle_insert', as: :items_vehicle_insert
  get    '/items_new_order', to: 'orders#new_order', as: :items_new_order
  post   '/items_new_order', to: 'orders#add_item_to_new_order', as: :add_item_to_new_order

  get    '/output/:destination', to: 'orders#output', as: :output
  post   '/output/add_item', to: 'orders#add_item', as: :add_item_to_order
  # get    '/output/office', to: 'items#output_office', as: :output_office
  # get    '/output/worksheet', to: 'items#output_worksheet', as: :output_worksheet
  # get    '/output/vehicle', to: 'items#output_vehicle', as: :output_vehicle
  # get    '/output/equipment', to: 'items#output_equipment', as: :output_equipment

end
