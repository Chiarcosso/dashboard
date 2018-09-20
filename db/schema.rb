# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180920073717) do

  create_table "article_categories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "ancestry"
    t.integer  "ancestry_depth", default: 0
    t.index ["ancestry"], name: "index_article_categories_on_ancestry", using: :btree
  end

  create_table "article_categories_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "parent_id"
    t.integer "child_id"
  end

  create_table "article_categorizations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "article_id"
    t.integer "category_id"
    t.index ["article_id"], name: "fk_rails_02ba750baf", using: :btree
  end

  create_table "article_compatibilities", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "article_id",          null: false
    t.integer  "original_article_id", null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["article_id"], name: "index_article_compatibilities_on_article_id", using: :btree
    t.index ["original_article_id"], name: "index_article_compatibilities_on_original_article_id", using: :btree
  end

  create_table "articles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "barcode"
    t.string   "manufacturerCode"
    t.string   "name"
    t.text     "description",      limit: 65535
    t.decimal  "containedAmount",                precision: 12, scale: 3, default: "1.0", null: false
    t.decimal  "minimalReserve",                 precision: 12, scale: 3
    t.datetime "created_at",                                                              null: false
    t.datetime "updated_at",                                                              null: false
    t.integer  "manufacturer_id"
    t.integer  "created_by_id"
    t.integer  "measure_unit",     limit: 3,                                              null: false
    t.index ["created_by_id"], name: "index_articles_on_created_by_id", using: :btree
    t.index ["manufacturer_id"], name: "index_articles_on_manufacturer_id", using: :btree
  end

  create_table "badge_assignments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "badge_id",   null: false
    t.integer  "person_id",  null: false
    t.date     "from",       null: false
    t.date     "to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["badge_id"], name: "index_badge_assignments_on_badge_id", using: :btree
    t.index ["person_id"], name: "index_badge_assignments_on_person_id", using: :btree
  end

  create_table "badges", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "code",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_badges_on_code", using: :btree
  end

  create_table "carwash_driver_codes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "code",                       null: false
    t.integer  "person_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.boolean  "disabled",   default: false, null: false
    t.index ["code"], name: "index_carwash_driver_codes_on_code", unique: true, using: :btree
    t.index ["disabled"], name: "index_carwash_driver_codes_on_disabled", using: :btree
    t.index ["person_id"], name: "index_carwash_driver_codes_on_person_id", using: :btree
  end

  create_table "carwash_special_codes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "label",                        null: false
    t.string   "code",                         null: false
    t.integer  "carwash_code", default: 0,     null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.boolean  "disabled",     default: false, null: false
    t.index ["disabled"], name: "index_carwash_special_codes_on_disabled", using: :btree
  end

  create_table "carwash_usages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "session_id",              null: false
    t.integer  "person_id"
    t.integer  "vehicle_1_id"
    t.integer  "vehicle_2_id"
    t.string   "row",                     null: false
    t.datetime "starting_time",           null: false
    t.datetime "ending_time"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "carwash_special_code_id"
    t.index ["carwash_special_code_id"], name: "index_carwash_usages_on_carwash_special_code_id", using: :btree
    t.index ["person_id"], name: "index_carwash_usages_on_person_id", using: :btree
    t.index ["vehicle_1_id"], name: "index_carwash_usages_on_vehicle_1_id", using: :btree
    t.index ["vehicle_2_id"], name: "index_carwash_usages_on_vehicle_2_id", using: :btree
  end

  create_table "carwash_vehicle_codes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "code",                                 null: false
    t.integer  "vehicle_id"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.boolean  "disabled",             default: false, null: false
    t.integer  "external_vehicles_id"
    t.index ["code"], name: "index_carwash_vehicle_codes_on_code", unique: true, using: :btree
    t.index ["disabled"], name: "index_carwash_vehicle_codes_on_disabled", using: :btree
    t.index ["external_vehicles_id"], name: "index_carwash_vehicle_codes_on_external_vehicles_id", using: :btree
    t.index ["vehicle_id"], name: "index_carwash_vehicle_codes_on_vehicle_id", using: :btree
  end

  create_table "companies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",                                               null: false
    t.string   "vat_number",              limit: 17
    t.string   "ssn",                     limit: 30
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.boolean  "workshop",                           default: false, null: false
    t.boolean  "client",                             default: false, null: false
    t.boolean  "supplier",                           default: false, null: false
    t.boolean  "vehicle_manufacturer",               default: false, null: false
    t.boolean  "transporter",                        default: false, null: false
    t.integer  "main_company_address_id"
    t.integer  "main_mail_address_id"
    t.integer  "main_phone_number_id"
    t.integer  "pec_mail_address_id"
    t.string   "notes"
    t.boolean  "institution",                        default: false, null: false
    t.boolean  "formation_institute",                default: false, null: false
    t.integer  "parent_company_id"
    t.integer  "company_group_id"
    t.boolean  "item_manufacturer",                  default: false, null: false
    t.index ["client"], name: "index_companies_on_client", using: :btree
    t.index ["formation_institute"], name: "index_companies_on_formation_institute", using: :btree
    t.index ["institution"], name: "index_companies_on_institution", using: :btree
    t.index ["main_company_address_id"], name: "fk_rails_396db41126", using: :btree
    t.index ["main_mail_address_id"], name: "fk_rails_3cdc7018e8", using: :btree
    t.index ["main_phone_number_id"], name: "fk_rails_2ff45ceb15", using: :btree
    t.index ["pec_mail_address_id"], name: "fk_rails_15313248bb", using: :btree
    t.index ["supplier"], name: "index_companies_on_supplier", using: :btree
    t.index ["transporter"], name: "index_companies_on_transporter", using: :btree
    t.index ["vehicle_manufacturer"], name: "index_companies_on_vehicle_manufacturer", using: :btree
    t.index ["workshop"], name: "index_companies_on_workshop", using: :btree
  end

  create_table "company_addresses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "company_id",                                                     null: false
    t.decimal  "geo_position_lat",       precision: 9, scale: 6
    t.decimal  "geo_position_lng",       precision: 9, scale: 6
    t.string   "street",                                                         null: false
    t.string   "number",                                                         null: false
    t.string   "internal"
    t.integer  "geo_city_id",                                                    null: false
    t.string   "zip",                                                            null: false
    t.integer  "geo_locality_id"
    t.string   "location_qualification",                                         null: false
    t.boolean  "closed",                                         default: false, null: false
    t.string   "notes"
    t.datetime "created_at",                                                     null: false
    t.datetime "updated_at",                                                     null: false
    t.boolean  "workshop",                                       default: false, null: false
    t.boolean  "loading_facility",                               default: false, null: false
    t.boolean  "unloading_facility",                             default: false, null: false
    t.index ["company_id"], name: "index_company_addresses_on_company_id", using: :btree
    t.index ["geo_city_id"], name: "index_company_addresses_on_geo_city_id", using: :btree
    t.index ["geo_locality_id"], name: "index_company_addresses_on_geo_locality_id", using: :btree
    t.index ["location_qualification"], name: "index_company_addresses_on_location_qualification", using: :btree
    t.index ["number"], name: "index_company_addresses_on_number", using: :btree
    t.index ["street", "number", "internal", "zip", "geo_city_id"], name: "company_address_unique", unique: true, using: :btree
  end

  create_table "company_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name",                null: false
    t.text   "notes", limit: 65535
  end

  create_table "company_mail_addresses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "company_id",                                        null: false
    t.string   "address",                                           null: false
    t.string   "address_qualification", default: "Sede secondaria", null: false
    t.boolean  "pec"
    t.string   "notes"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.integer  "company_address_id"
    t.index ["company_address_id"], name: "index_company_mail_addresses_on_company_address_id", using: :btree
    t.index ["company_id"], name: "index_company_mail_addresses_on_company_id", using: :btree
  end

  create_table "company_people", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "person_id"
    t.integer  "company_id"
    t.integer  "company_relation_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.boolean  "acting",              default: true, null: false
    t.index ["company_id"], name: "index_company_people_on_company_id", using: :btree
    t.index ["company_relation_id"], name: "index_company_people_on_company_relation_id", using: :btree
    t.index ["person_id", "company_id", "company_relation_id"], name: "company_people_unique", unique: true, using: :btree
    t.index ["person_id"], name: "index_company_people_on_person_id", using: :btree
  end

  create_table "company_phone_numbers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "company_id",                                                 null: false
    t.string   "international_prefix",                                       null: false
    t.string   "prefix",                                                     null: false
    t.string   "number"
    t.integer  "number_type",          limit: 1
    t.string   "number_qualification",           default: "Sede secondaria", null: false
    t.string   "notes"
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
    t.integer  "company_address_id"
    t.index ["company_address_id"], name: "index_company_phone_numbers_on_company_address_id", using: :btree
    t.index ["company_id"], name: "index_company_phone_numbers_on_company_id", using: :btree
  end

  create_table "company_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "equipment", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "equipment_articles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "equipment_id", null: false
    t.integer  "article_id",   null: false
    t.string   "size"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["article_id"], name: "index_equipment_articles_on_article_id", using: :btree
    t.index ["equipment_id"], name: "index_equipment_articles_on_equipment_id", using: :btree
  end

  create_table "equipment_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "external_vehicles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "owner_id",            null: false
    t.string   "plate",               null: false
    t.integer  "id_veicolo",          null: false
    t.integer  "id_fornitore",        null: false
    t.integer  "vehicle_type_id",     null: false
    t.integer  "vehicle_typology_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["owner_id"], name: "index_external_vehicles_on_owner_id", using: :btree
    t.index ["plate"], name: "index_external_vehicles_on_plate", using: :btree
    t.index ["vehicle_type_id"], name: "index_external_vehicles_on_vehicle_type_id", using: :btree
    t.index ["vehicle_typology_id"], name: "index_external_vehicles_on_vehicle_typology_id", using: :btree
  end

  create_table "festivities", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "day",        null: false
    t.integer  "month",      null: false
    t.integer  "year"
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["day", "month", "year"], name: "index_festivities_on_day_and_month_and_year", unique: true, using: :btree
    t.index ["month"], name: "index_festivities_on_month", using: :btree
    t.index ["year"], name: "index_festivities_on_year", using: :btree
  end

  create_table "gears", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",              null: false
    t.string   "serial",            null: false
    t.integer  "assigned_to"
    t.string   "assigned_to_class"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "geo_cities", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",            null: false
    t.integer  "geo_province_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "zip"
    t.index ["geo_province_id"], name: "index_geo_cities_on_geo_province_id", using: :btree
    t.index ["name", "geo_province_id", "zip"], name: "index_geo_cities_on_name_and_geo_province_id_and_zip", unique: true, using: :btree
    t.index ["name"], name: "index_geo_cities_on_name", using: :btree
  end

  create_table "geo_localities", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",        null: false
    t.integer  "geo_city_id", null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "zip"
    t.index ["geo_city_id"], name: "index_geo_localities_on_geo_city_id", using: :btree
    t.index ["name", "geo_city_id", "zip"], name: "index_geo_localities_on_name_and_geo_city_id_and_zip", unique: true, using: :btree
    t.index ["name"], name: "index_geo_localities_on_name", using: :btree
  end

  create_table "geo_provinces", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",         null: false
    t.string   "code"
    t.integer  "geo_state_id", null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["geo_state_id"], name: "index_geo_provinces_on_geo_state_id", using: :btree
    t.index ["name", "geo_state_id", "code"], name: "index_geo_provinces_on_name_and_geo_state_id_and_code", unique: true, using: :btree
    t.index ["name"], name: "index_geo_provinces_on_name", using: :btree
  end

  create_table "geo_states", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",        null: false
    t.string   "code",        null: false
    t.integer  "language_id", null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["code"], name: "index_geo_states_on_code", using: :btree
    t.index ["language_id"], name: "index_geo_states_on_languages_id", using: :btree
    t.index ["name"], name: "index_geo_states_on_name", unique: true, using: :btree
  end

  create_table "granted_leaves", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "leave_code_id",             null: false
    t.integer  "person_id",                 null: false
    t.datetime "from",                      null: false
    t.datetime "to",                        null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.date     "date"
    t.integer  "break",         default: 0, null: false
    t.index ["leave_code_id", "person_id", "from", "to"], name: "granted_leaves_uniqs", unique: true, using: :btree
    t.index ["leave_code_id"], name: "index_granted_leaves_on_leave_code_id", using: :btree
    t.index ["person_id"], name: "index_granted_leaves_on_person_id", using: :btree
  end

  create_table "item_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "office_id"
    t.integer  "vehicle_id"
    t.integer  "item_id"
    t.date     "since"
    t.date     "to"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "person_id"
    t.integer  "worksheet_id"
    t.index ["item_id"], name: "index_item_relations_on_item_id", using: :btree
    t.index ["office_id"], name: "index_item_relations_on_office_id", using: :btree
    t.index ["person_id"], name: "index_item_relations_on_person_id", using: :btree
    t.index ["vehicle_id"], name: "index_item_relations_on_vehicle_id", using: :btree
    t.index ["worksheet_id"], name: "index_item_relations_on_worksheet_id", using: :btree
  end

  create_table "items", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.date     "purchaseDate"
    t.decimal  "price",                               precision: 9, scale: 2, default: "0.0", null: false
    t.decimal  "discount",                            precision: 5, scale: 2, default: "0.0", null: false
    t.string   "serial"
    t.integer  "state",                 limit: 3
    t.text     "notes",                 limit: 65535
    t.date     "expiringDate"
    t.datetime "created_at",                                                                  null: false
    t.datetime "updated_at",                                                                  null: false
    t.integer  "article_id",                                                                  null: false
    t.integer  "transportDocument_id"
    t.integer  "transport_document_id"
    t.string   "barcode"
    t.integer  "position_code_id",                                                            null: false
    t.decimal  "remaining_quantity",                  precision: 7, scale: 2, default: "0.0", null: false
    t.index ["article_id"], name: "index_items_on_article_id", using: :btree
    t.index ["position_code_id"], name: "index_items_on_position_code_id", using: :btree
    t.index ["transportDocument_id"], name: "index_items_on_transportDocument_id", using: :btree
    t.index ["transport_document_id"], name: "index_items_on_transport_document_id", using: :btree
  end

  create_table "languages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_languages_on_name", unique: true, using: :btree
  end

  create_table "leave_codes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "code",                                     null: false
    t.integer  "afterhours",      limit: 2, default: 0,    null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "description"
    t.boolean  "studio_relevant",           default: true, null: false
    t.index ["code"], name: "index_leave_codes_on_code", unique: true, using: :btree
  end

  create_table "mdc_users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "user",                   null: false
    t.string   "activation_code",        null: false
    t.integer  "assigned_to_company_id"
    t.integer  "assigned_to_person_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["assigned_to_company_id"], name: "index_mdc_users_on_assigned_to_company_id", using: :btree
    t.index ["assigned_to_person_id"], name: "index_mdc_users_on_assigned_to_person_id", using: :btree
  end

  create_table "mobile_workshop_items", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "storage_item_id",                   null: false
    t.decimal  "remaining_quantity", precision: 10, null: false
    t.integer  "mobile_workshop_id",                null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.index ["mobile_workshop_id"], name: "fk_rails_0662c38a37", using: :btree
    t.index ["storage_item_id"], name: "fk_rails_077a2def56", using: :btree
  end

  create_table "mssql_references", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "local_object_type"
    t.integer  "local_object_id",     null: false
    t.integer  "remote_object_id",    null: false
    t.string   "remote_object_table", null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["local_object_id", "local_object_type", "remote_object_id", "remote_object_table"], name: "mssql_references_uniques", unique: true, using: :btree
    t.index ["local_object_type", "local_object_id"], name: "index_mssql_references_on_local_object_type_and_local_object_id", using: :btree
    t.index ["remote_object_table"], name: "index_mssql_references_on_remote_object_table", using: :btree
  end

  create_table "offices", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_articles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "order_id"
    t.integer  "article_id"
    t.integer  "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_order_articles_on_article_id", using: :btree
    t.index ["order_id"], name: "index_order_articles_on_order_id", using: :btree
  end

  create_table "orders", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "number"
    t.date     "date"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "supplier_id"
    t.integer  "created_by_id"
    t.index ["created_by_id"], name: "index_orders_on_created_by_id", using: :btree
    t.index ["supplier_id"], name: "index_orders_on_supplier_id", using: :btree
  end

  create_table "orders_transport_documents", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "order_id",              null: false
    t.integer "transport_document_id", null: false
  end

  create_table "output_order_items", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "item_id"
    t.integer  "output_order_id"
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
    t.decimal  "quantity",             precision: 7, scale: 2, default: "1.0", null: false
    t.boolean  "from_mobile_workshop",                         default: false, null: false
    t.index ["item_id"], name: "index_output_order_items_on_item_id", using: :btree
    t.index ["output_order_id"], name: "index_output_order_items_on_output_order_id", using: :btree
  end

  create_table "output_orders", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "createdBy_id"
    t.string   "destination_type",                 null: false
    t.integer  "destination_id",                   null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.boolean  "processed",        default: false
    t.integer  "receiver_id"
    t.index ["createdBy_id"], name: "index_output_orders_on_createdBy_id", using: :btree
    t.index ["destination_type", "destination_id"], name: "index_output_orders_on_destination_type_and_destination_id", using: :btree
    t.index ["receiver_id"], name: "index_output_orders_on_receiver_id", using: :btree
  end

  create_table "people", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",                     default: "", null: false
    t.string   "surname",                  default: "", null: false
    t.text     "notes",      limit: 65535
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "mdc_user"
  end

  create_table "position_codes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "floor",       limit: 1, default: 0, null: false
    t.integer  "row",         limit: 1, default: 0, null: false
    t.integer  "level",       limit: 1, default: 0, null: false
    t.integer  "sector",      limit: 1, default: 0, null: false
    t.integer  "section",     limit: 1, default: 0, null: false
    t.string   "description"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  create_table "prepaid_cards", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "serial",                        null: false
    t.integer  "person_id"
    t.integer  "pin",                           null: false
    t.boolean  "dismissed",     default: false, null: false
    t.date     "expiring_date",                 null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "company_id",                    null: false
    t.index ["company_id"], name: "index_prepaid_cards_on_company_id", using: :btree
    t.index ["person_id"], name: "index_prepaid_cards_on_person_id", using: :btree
    t.index ["serial"], name: "index_prepaid_cards_on_serial", unique: true, using: :btree
  end

  create_table "presence_records", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.date     "date",                null: false
    t.integer  "start_ts_id",         null: false
    t.integer  "end_ts_id"
    t.integer  "person_id"
    t.integer  "actual_duration"
    t.integer  "calculated_duration"
    t.boolean  "break",               null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.datetime "calculated_start",    null: false
    t.datetime "calculated_end"
    t.integer  "set_day_time"
    t.string   "anomaly"
    t.index ["date"], name: "index_presence_records_on_date", using: :btree
    t.index ["end_ts_id"], name: "index_presence_records_on_end_ts_id", using: :btree
    t.index ["person_id"], name: "index_presence_records_on_person_id", using: :btree
    t.index ["start_ts_id"], name: "index_presence_records_on_start_ts_id", using: :btree
  end

  create_table "presence_timestamps", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "badge_id",                   null: false
    t.datetime "time"
    t.integer  "sensor_id",                  null: false
    t.boolean  "deleted",    default: false
    t.boolean  "added",      default: false
    t.string   "file"
    t.integer  "row"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.boolean  "entering"
    t.index ["badge_id", "time", "sensor_id"], name: "index_presence_timestamps_on_badge_id_and_time_and_sensor_id", unique: true, using: :btree
    t.index ["badge_id"], name: "index_presence_timestamps_on_badge_id", using: :btree
    t.index ["sensor_id"], name: "index_presence_timestamps_on_sensor_id", using: :btree
  end

  create_table "queries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "model_class",               null: false
    t.text     "query",       limit: 65535, null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "representatives", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "office_id"
    t.integer  "user_id"
    t.integer  "level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["office_id"], name: "index_representatives_on_office_id", using: :btree
    t.index ["user_id"], name: "index_representatives_on_user_id", using: :btree
  end

  create_table "roles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "resource_type"
    t.integer  "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
    t.index ["name"], name: "index_roles_on_name", using: :btree
  end

  create_table "sensors", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "number"
    t.string   "name"
    t.boolean  "presence_relevant"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "transport_documents", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "number"
    t.date     "date"
    t.string   "reason"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "order_id"
    t.integer  "sender_id"
    t.integer  "vector_id"
    t.integer  "subvector_id"
    t.integer  "receiver_id"
    t.index ["order_id"], name: "index_transport_documents_on_order_id", using: :btree
    t.index ["receiver_id"], name: "index_transport_documents_on_receiver_id", using: :btree
    t.index ["sender_id"], name: "index_transport_documents_on_sender_id", using: :btree
    t.index ["subvector_id"], name: "index_transport_documents_on_subvector_id", using: :btree
    t.index ["vector_id"], name: "index_transport_documents_on_vector_id", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "email",                  default: "", null: false
    t.string   "username",               default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "person_id",                           null: false
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["person_id"], name: "index_users_on_person_id", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "users_roles", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree
  end

  create_table "vehicle_categories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",                      null: false
    t.text     "description", limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["name"], name: "index_vehicle_categories_on_name", using: :btree
    t.index ["name"], name: "vehicle_categories_unique_name", unique: true, using: :btree
  end

  create_table "vehicle_check_sessions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "theoretical_km"
    t.integer  "real_km"
    t.date     "date",                                                   null: false
    t.integer  "operator_id",                                            null: false
    t.integer  "theoretical_duration",                                   null: false
    t.integer  "real_duration"
    t.integer  "worksheet_id"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.integer  "vehicle_id"
    t.integer  "external_vehicle_id"
    t.datetime "finished"
    t.text     "log",                  limit: 65535
    t.integer  "myofficina_reference"
    t.string   "station",                            default: "carwash", null: false
    t.index ["external_vehicle_id"], name: "index_vehicle_check_sessions_on_external_vehicle_id", using: :btree
    t.index ["operator_id"], name: "index_vehicle_check_sessions_on_operator_id", using: :btree
    t.index ["vehicle_id"], name: "index_vehicle_check_sessions_on_vehicle_id", using: :btree
    t.index ["worksheet_id"], name: "index_vehicle_check_sessions_on_worksheet_id", using: :btree
  end

  create_table "vehicle_checks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "code",                                                   null: false
    t.integer  "vehicle_id"
    t.integer  "vehicle_type_id"
    t.integer  "vehicle_typology_id"
    t.integer  "importance",                                             null: false
    t.integer  "duration",                                               null: false
    t.boolean  "check_driver",                        default: true,     null: false
    t.boolean  "check_carwash",                       default: true,     null: false
    t.boolean  "check_workshop",                      default: true,     null: false
    t.integer  "frequency_km"
    t.integer  "frequency_time"
    t.integer  "alert_before_km"
    t.integer  "alert_before_time"
    t.boolean  "both_expired",                        default: false,    null: false
    t.boolean  "generate_worksheet",                  default: true,     null: false
    t.string   "label",                                                  null: false
    t.decimal  "val_min",              precision: 10
    t.decimal  "val_max",              precision: 10
    t.integer  "group_id"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.string   "measure_unit"
    t.string   "datatype",                            default: "select", null: false
    t.string   "options"
    t.string   "notify_to"
    t.string   "reference_value_path"
    t.index ["check_carwash"], name: "index_vehicle_checks_on_check_carwash", using: :btree
    t.index ["check_driver"], name: "index_vehicle_checks_on_check_driver", using: :btree
    t.index ["check_workshop"], name: "index_vehicle_checks_on_check_workshop", using: :btree
    t.index ["code"], name: "index_vehicle_checks_on_code", using: :btree
    t.index ["importance"], name: "index_vehicle_checks_on_importance", using: :btree
    t.index ["label"], name: "index_vehicle_checks_on_label", using: :btree
    t.index ["vehicle_id"], name: "index_vehicle_checks_on_vehicle_id", using: :btree
    t.index ["vehicle_type_id"], name: "index_vehicle_checks_on_vehicle_type_id", using: :btree
    t.index ["vehicle_typology_id"], name: "index_vehicle_checks_on_vehicle_typology_id", using: :btree
  end

  create_table "vehicle_equipments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vehicle_information_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",                   null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "data_type",  default: 0, null: false
  end

  create_table "vehicle_informations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_id",                              null: false
    t.string   "information"
    t.date     "date",                                    null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "vehicle_information_type_id", default: 1, null: false
    t.index ["vehicle_id"], name: "index_vehicle_informations_on_vehicle_id", using: :btree
    t.index ["vehicle_information_type_id"], name: "index_vehicle_informations_on_vehicle_information_type_id", using: :btree
  end

  create_table "vehicle_model_categories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_model_id",    null: false
    t.integer  "vehicle_category_id", null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["vehicle_category_id"], name: "index_vehicle_model_categories_on_vehicle_category_id", using: :btree
    t.index ["vehicle_model_id"], name: "index_vehicle_model_categories_on_vehicle_model_id", using: :btree
  end

  create_table "vehicle_model_equipments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_model_id",     null: false
    t.integer  "vehicle_equipment_id", null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["vehicle_equipment_id"], name: "index_vehicle_model_equipments_on_vehicle_equipment_id", using: :btree
    t.index ["vehicle_model_id"], name: "index_vehicle_model_equipments_on_vehicle_model_id", using: :btree
  end

  create_table "vehicle_model_information_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_model_id",            null: false
    t.integer  "vehicle_information_type_id", null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["vehicle_information_type_id"], name: "vehicle_model_vehicle_information_type_index", using: :btree
    t.index ["vehicle_model_id"], name: "vehicle_model_vehicle_model_index", using: :btree
  end

  create_table "vehicle_model_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_model_id", null: false
    t.integer  "vehicle_type_id",  null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["vehicle_model_id"], name: "index_vehicle_model_types_on_vehicle_model_id", using: :btree
    t.index ["vehicle_type_id"], name: "index_vehicle_model_types_on_vehicle_type_id", using: :btree
  end

  create_table "vehicle_model_typologies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_model_id",    null: false
    t.integer  "vehicle_typology_id", null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["vehicle_model_id"], name: "index_vehicle_model_typologies_on_vehicle_model_id", using: :btree
    t.index ["vehicle_typology_id"], name: "index_vehicle_model_typologies_on_vehicle_typology_id", using: :btree
  end

  create_table "vehicle_models", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "manufacturer_id"
    t.text     "description",     limit: 65535
    t.index ["manufacturer_id"], name: "index_vehicle_models_on_manufacturer_id", using: :btree
  end

  create_table "vehicle_performed_checks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_check_session_id",                           null: false
    t.integer  "vehicle_check_id",                                   null: false
    t.string   "value"
    t.string   "notes"
    t.integer  "performed",                limit: 3, default: 0,     null: false
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.datetime "time"
    t.boolean  "is_last",                            default: false, null: false
    t.integer  "vehicle_id"
    t.integer  "external_vehicle_id"
    t.boolean  "mandatory",                          default: false, null: false
    t.integer  "user_id"
    t.integer  "myofficina_reference"
    t.integer  "myofficina_odl_reference"
    t.index ["external_vehicle_id"], name: "index_vehicle_performed_checks_on_external_vehicle_id", using: :btree
    t.index ["is_last", "external_vehicle_id", "vehicle_check_id"], name: "vpf_external_vehicle_last_check", using: :btree
    t.index ["is_last", "vehicle_id", "vehicle_check_id"], name: "vpf_vehicle_last_check", using: :btree
    t.index ["user_id"], name: "index_vehicle_performed_checks_on_user_id", using: :btree
    t.index ["vehicle_check_id"], name: "index_vehicle_performed_checks_on_vehicle_check_id", using: :btree
    t.index ["vehicle_check_session_id", "vehicle_check_id"], name: "vehicle_check_session_check", unique: true, using: :btree
    t.index ["vehicle_check_session_id"], name: "index_vehicle_performed_checks_on_vehicle_check_session_id", using: :btree
    t.index ["vehicle_id"], name: "index_vehicle_performed_checks_on_vehicle_id", using: :btree
  end

  create_table "vehicle_properties", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_id", null: false
    t.string   "owner_type"
    t.integer  "owner_id",   null: false
    t.date     "date_since"
    t.date     "date_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_vehicle_properties_on_owner_type_and_owner_id", using: :btree
    t.index ["vehicle_id"], name: "index_vehicle_properties_on_vehicle_id", using: :btree
  end

  create_table "vehicle_type_categories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_type_id",     null: false
    t.integer  "vehicle_category_id", null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["vehicle_category_id"], name: "index_vehicle_type_categories_on_vehicle_category_id", using: :btree
    t.index ["vehicle_type_id"], name: "index_vehicle_type_categories_on_vehicle_type_id", using: :btree
  end

  create_table "vehicle_type_equipments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_type_id",      null: false
    t.integer  "vehicle_equipment_id", null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["vehicle_equipment_id"], name: "index_vehicle_type_equipments_on_vehicle_equipment_id", using: :btree
    t.index ["vehicle_type_id"], name: "index_vehicle_type_equipments_on_vehicle_type_id", using: :btree
  end

  create_table "vehicle_type_information_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_type_id",             null: false
    t.integer  "vehicle_information_type_id", null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["vehicle_information_type_id"], name: "vehicle_type_information_type_index", using: :btree
    t.index ["vehicle_type_id"], name: "vehicle_type_vehicle_type_index", using: :btree
  end

  create_table "vehicle_type_typologies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_type_id",     null: false
    t.integer  "vehicle_typology_id", null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["vehicle_type_id"], name: "index_vehicle_type_typologies_on_vehicle_type_id", using: :btree
    t.index ["vehicle_typology_id"], name: "index_vehicle_type_typologies_on_vehicle_typology_id", using: :btree
  end

  create_table "vehicle_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",                     null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "carwash_type", default: 0, null: false
  end

  create_table "vehicle_typologies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vehicle_typology_categories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_typology_id", null: false
    t.integer  "vehicle_category_id", null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["vehicle_category_id"], name: "index_vehicle_typology_categories_on_vehicle_category_id", using: :btree
    t.index ["vehicle_typology_id"], name: "index_vehicle_typology_categories_on_vehicle_typology_id", using: :btree
  end

  create_table "vehicle_typology_equipments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_typology_id",  null: false
    t.integer  "vehicle_equipment_id", null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["vehicle_equipment_id"], name: "index_vehicle_typology_equipments_on_vehicle_equipment_id", using: :btree
    t.index ["vehicle_typology_id"], name: "index_vehicle_typology_equipments_on_vehicle_typology_id", using: :btree
  end

  create_table "vehicle_typology_information_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_typology_id",         null: false
    t.integer  "vehicle_information_type_id", null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["vehicle_information_type_id"], name: "vehicle_typology_vehicle_information_type_index", using: :btree
    t.index ["vehicle_typology_id"], name: "vehicle_typology_vehicle_typology_index", using: :btree
  end

  create_table "vehicle_vehicle_equipments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vehicle_id",           null: false
    t.integer  "vehicle_equipment_id", null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["vehicle_equipment_id"], name: "index_vehicle_vehicle_equipments_on_vehicle_equipment_id", using: :btree
    t.index ["vehicle_id"], name: "index_vehicle_vehicle_equipments_on_vehicle_id", using: :btree
  end

  create_table "vehicles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.boolean  "dismissed",                         default: false
    t.date     "registration_date"
    t.string   "initial_serial"
    t.integer  "mileage"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.integer  "property_id"
    t.integer  "model_id"
    t.text     "notes",               limit: 65535
    t.integer  "vehicle_type_id",                   default: 1,     null: false
    t.integer  "vehicle_typology_id",               default: 1,     null: false
    t.string   "serie"
    t.integer  "carwash_code"
    t.integer  "vehicle_category_id",               default: 1,     null: false
    t.string   "registration_model"
    t.index ["model_id"], name: "index_vehicles_on_model_id", using: :btree
    t.index ["property_id"], name: "index_vehicles_on_property_id", using: :btree
    t.index ["vehicle_category_id"], name: "index_vehicles_on_vehicle_category_id", using: :btree
    t.index ["vehicle_type_id"], name: "index_vehicles_on_vehicle_type_id", using: :btree
    t.index ["vehicle_typology_id"], name: "index_vehicles_on_vehicle_typology_id", using: :btree
  end

  create_table "working_schedules", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "person_id",                                     null: false
    t.string   "agreement_from_s",                              null: false
    t.string   "agreement_to_s",                                null: false
    t.string   "contract_from_s",                               null: false
    t.string   "contract_to_s",                                 null: false
    t.integer  "weekday",                                       null: false
    t.boolean  "contractor",                    default: false, null: false
    t.integer  "break",                                         null: false
    t.integer  "months_unpaid_days",            default: 0,     null: false
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.integer  "start_flexibility",             default: 0,     null: false
    t.integer  "break_flexibility",             default: 15,    null: false
    t.float    "expected_hours",     limit: 24, default: 9.0,   null: false
    t.integer  "flexibility",                   default: 0,     null: false
    t.index ["contractor"], name: "index_working_schedules_on_contractor", using: :btree
    t.index ["person_id", "weekday"], name: "index_working_schedules_on_person_id_and_weekday", unique: true, using: :btree
    t.index ["person_id"], name: "index_working_schedules_on_person_id", using: :btree
    t.index ["weekday"], name: "index_working_schedules_on_weekday", using: :btree
  end

  create_table "worksheet_operations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "worksheet_id"
    t.integer  "workshop_operation_id"
    t.datetime "starting_time"
    t.datetime "ending_time"
    t.integer  "person_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.index ["person_id"], name: "index_worksheet_operations_on_person_id", using: :btree
    t.index ["worksheet_id"], name: "index_worksheet_operations_on_worksheet_id", using: :btree
    t.index ["workshop_operation_id"], name: "index_worksheet_operations_on_workshop_operation_id", using: :btree
  end

  create_table "worksheets", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "code",                                                                         null: false
    t.date     "closingDate"
    t.integer  "vehicle_id",                                                                   null: false
    t.datetime "created_at",                                                                   null: false
    t.datetime "updated_at",                                                                   null: false
    t.decimal  "hours",                            precision: 4, scale: 1, default: "0.0",     null: false
    t.string   "vehicle_type",                                             default: "Vehicle", null: false
    t.string   "notes"
    t.date     "opening_date"
    t.datetime "exit_time"
    t.integer  "real_duration",                                            default: 0,         null: false
    t.date     "creation_date"
    t.text     "log",                limit: 65535
    t.boolean  "suspended",                                                default: false,     null: false
    t.string   "station"
    t.boolean  "closed",                                                   default: false,     null: false
    t.string   "pdf_path"
    t.datetime "last_starting_time"
    t.datetime "last_stopping_time"
    t.boolean  "paused",                                                   default: true,      null: false
    t.index ["code"], name: "index_worksheets_on_code", unique: true, using: :btree
    t.index ["vehicle_id"], name: "index_worksheets_on_vehicle_id", using: :btree
  end

  create_table "workshop_brands", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "workshop_id", null: false
    t.integer  "brand_id",    null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["brand_id"], name: "index_workshop_brands_on_brand_id", using: :btree
    t.index ["workshop_id"], name: "index_workshop_brands_on_workshop_id", using: :btree
  end

  create_table "workshop_operation_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",                   null: false
    t.integer  "frequency"
    t.integer  "frequency_mu", limit: 1
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["name"], name: "index_workshop_operation_groups_on_name", using: :btree
  end

  create_table "workshop_operations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",                                              null: false
    t.integer  "frequency"
    t.integer  "frequency_mu",         limit: 1
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.integer  "worksheet_id",                                      null: false
    t.integer  "user_id"
    t.datetime "starting_time"
    t.datetime "ending_time"
    t.integer  "real_duration",                      default: 0,    null: false
    t.integer  "myofficina_reference"
    t.string   "notes"
    t.text     "log",                  limit: 65535
    t.boolean  "paused",                             default: true, null: false
    t.datetime "last_starting_time"
    t.datetime "last_stopping_time"
    t.index ["name"], name: "index_workshop_operations_on_name", using: :btree
    t.index ["user_id"], name: "index_workshop_operations_on_user_id", using: :btree
    t.index ["worksheet_id"], name: "index_workshop_operations_on_worksheet_id", using: :btree
  end

  add_foreign_key "article_categorizations", "article_categories", column: "article_id"
  add_foreign_key "article_compatibilities", "articles"
  add_foreign_key "articles", "companies", column: "manufacturer_id"
  add_foreign_key "articles", "users", column: "created_by_id"
  add_foreign_key "badge_assignments", "badges"
  add_foreign_key "badge_assignments", "people"
  add_foreign_key "carwash_driver_codes", "people"
  add_foreign_key "carwash_usages", "carwash_special_codes"
  add_foreign_key "carwash_usages", "people"
  add_foreign_key "carwash_usages", "vehicles", column: "vehicle_1_id"
  add_foreign_key "carwash_usages", "vehicles", column: "vehicle_2_id"
  add_foreign_key "carwash_vehicle_codes", "external_vehicles", column: "external_vehicles_id"
  add_foreign_key "carwash_vehicle_codes", "vehicles"
  add_foreign_key "companies", "company_addresses", column: "main_company_address_id"
  add_foreign_key "companies", "company_mail_addresses", column: "main_mail_address_id"
  add_foreign_key "companies", "company_mail_addresses", column: "pec_mail_address_id"
  add_foreign_key "companies", "company_phone_numbers", column: "main_phone_number_id"
  add_foreign_key "company_addresses", "companies"
  add_foreign_key "company_addresses", "geo_cities"
  add_foreign_key "company_addresses", "geo_localities"
  add_foreign_key "company_mail_addresses", "companies"
  add_foreign_key "company_mail_addresses", "company_addresses"
  add_foreign_key "company_people", "companies"
  add_foreign_key "company_people", "company_relations"
  add_foreign_key "company_people", "people"
  add_foreign_key "company_phone_numbers", "companies"
  add_foreign_key "company_phone_numbers", "company_addresses"
  add_foreign_key "equipment_articles", "articles"
  add_foreign_key "equipment_articles", "equipment"
  add_foreign_key "external_vehicles", "vehicle_types"
  add_foreign_key "external_vehicles", "vehicle_typologies"
  add_foreign_key "geo_cities", "geo_provinces"
  add_foreign_key "geo_localities", "geo_cities"
  add_foreign_key "geo_provinces", "geo_states"
  add_foreign_key "geo_states", "languages"
  add_foreign_key "granted_leaves", "leave_codes"
  add_foreign_key "granted_leaves", "people"
  add_foreign_key "item_relations", "items"
  add_foreign_key "item_relations", "offices"
  add_foreign_key "item_relations", "people"
  add_foreign_key "item_relations", "vehicles"
  add_foreign_key "item_relations", "worksheets"
  add_foreign_key "items", "articles"
  add_foreign_key "items", "position_codes"
  add_foreign_key "items", "transport_documents"
  add_foreign_key "mdc_users", "companies", column: "assigned_to_company_id"
  add_foreign_key "mdc_users", "people", column: "assigned_to_person_id"
  add_foreign_key "mobile_workshop_items", "items", column: "storage_item_id"
  add_foreign_key "mobile_workshop_items", "offices", column: "mobile_workshop_id"
  add_foreign_key "order_articles", "articles"
  add_foreign_key "order_articles", "orders"
  add_foreign_key "orders", "companies", column: "supplier_id"
  add_foreign_key "orders", "users", column: "created_by_id"
  add_foreign_key "output_order_items", "items"
  add_foreign_key "output_order_items", "output_orders"
  add_foreign_key "output_orders", "people", column: "receiver_id"
  add_foreign_key "output_orders", "users", column: "createdBy_id"
  add_foreign_key "prepaid_cards", "people"
  add_foreign_key "presence_records", "people"
  add_foreign_key "presence_records", "presence_timestamps", column: "end_ts_id"
  add_foreign_key "presence_records", "presence_timestamps", column: "start_ts_id"
  add_foreign_key "presence_timestamps", "badges"
  add_foreign_key "presence_timestamps", "sensors"
  add_foreign_key "transport_documents", "companies", column: "receiver_id"
  add_foreign_key "transport_documents", "companies", column: "subvector_id"
  add_foreign_key "transport_documents", "companies", column: "vector_id"
  add_foreign_key "transport_documents", "orders"
  add_foreign_key "vehicle_check_sessions", "external_vehicles"
  add_foreign_key "vehicle_check_sessions", "people", column: "operator_id"
  add_foreign_key "vehicle_check_sessions", "vehicles"
  add_foreign_key "vehicle_check_sessions", "worksheets"
  add_foreign_key "vehicle_checks", "vehicle_types"
  add_foreign_key "vehicle_checks", "vehicle_typologies"
  add_foreign_key "vehicle_checks", "vehicles"
  add_foreign_key "vehicle_informations", "vehicle_information_types"
  add_foreign_key "vehicle_informations", "vehicles"
  add_foreign_key "vehicle_model_categories", "vehicle_categories"
  add_foreign_key "vehicle_model_categories", "vehicle_models"
  add_foreign_key "vehicle_model_equipments", "vehicle_equipments"
  add_foreign_key "vehicle_model_equipments", "vehicle_models"
  add_foreign_key "vehicle_model_information_types", "vehicle_information_types"
  add_foreign_key "vehicle_model_information_types", "vehicle_models"
  add_foreign_key "vehicle_model_types", "vehicle_models"
  add_foreign_key "vehicle_model_types", "vehicle_types"
  add_foreign_key "vehicle_model_typologies", "vehicle_models"
  add_foreign_key "vehicle_model_typologies", "vehicle_typologies"
  add_foreign_key "vehicle_models", "companies", column: "manufacturer_id"
  add_foreign_key "vehicle_performed_checks", "external_vehicles"
  add_foreign_key "vehicle_performed_checks", "vehicle_check_sessions"
  add_foreign_key "vehicle_performed_checks", "vehicle_checks"
  add_foreign_key "vehicle_performed_checks", "vehicles"
  add_foreign_key "vehicle_properties", "vehicles"
  add_foreign_key "vehicle_type_categories", "vehicle_categories"
  add_foreign_key "vehicle_type_categories", "vehicle_types"
  add_foreign_key "vehicle_type_equipments", "vehicle_equipments"
  add_foreign_key "vehicle_type_equipments", "vehicle_types"
  add_foreign_key "vehicle_type_information_types", "vehicle_information_types"
  add_foreign_key "vehicle_type_information_types", "vehicle_types"
  add_foreign_key "vehicle_type_typologies", "vehicle_types"
  add_foreign_key "vehicle_type_typologies", "vehicle_typologies"
  add_foreign_key "vehicle_typology_categories", "vehicle_categories"
  add_foreign_key "vehicle_typology_categories", "vehicle_typologies"
  add_foreign_key "vehicle_typology_equipments", "vehicle_equipments"
  add_foreign_key "vehicle_typology_equipments", "vehicle_typologies"
  add_foreign_key "vehicle_typology_information_types", "vehicle_information_types"
  add_foreign_key "vehicle_typology_information_types", "vehicle_typologies"
  add_foreign_key "vehicle_vehicle_equipments", "vehicle_equipments"
  add_foreign_key "vehicle_vehicle_equipments", "vehicles"
  add_foreign_key "vehicles", "companies", column: "property_id"
  add_foreign_key "vehicles", "vehicle_categories"
  add_foreign_key "vehicles", "vehicle_models", column: "model_id"
  add_foreign_key "vehicles", "vehicle_types"
  add_foreign_key "vehicles", "vehicle_typologies"
  add_foreign_key "working_schedules", "people"
  add_foreign_key "worksheet_operations", "people"
  add_foreign_key "worksheet_operations", "worksheets"
  add_foreign_key "worksheet_operations", "workshop_operations"
  add_foreign_key "workshop_operations", "users"
  add_foreign_key "workshop_operations", "worksheets"
end
