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

ActiveRecord::Schema.define(version: 20170126143828) do

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
  end

  create_table "articles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "barcode"
    t.string   "manufacturerCode"
    t.string   "name"
    t.text     "description",      limit: 65535
    t.integer  "containedAmount"
    t.integer  "minimalReserve"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.integer  "manufacturer_id"
    t.integer  "created_by_id"
    t.integer  "position_code_id"
    t.index ["created_by_id"], name: "index_articles_on_created_by_id", using: :btree
    t.index ["manufacturer_id"], name: "index_articles_on_manufacturer_id", using: :btree
    t.index ["position_code_id"], name: "index_articles_on_position_code_id", using: :btree
  end

  create_table "companies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "vat_number", limit: 17
    t.string   "ssn",        limit: 30
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "item_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "office_id"
    t.integer  "vehicle_id"
    t.integer  "item_id"
    t.date     "since"
    t.date     "to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_item_relations_on_item_id", using: :btree
    t.index ["office_id"], name: "index_item_relations_on_office_id", using: :btree
    t.index ["vehicle_id"], name: "index_item_relations_on_vehicle_id", using: :btree
  end

  create_table "items", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.date     "purchaseDate"
    t.decimal  "price",                               precision: 9, scale: 2
    t.decimal  "discount",                            precision: 5, scale: 2
    t.string   "serial"
    t.integer  "state",                 limit: 3
    t.text     "notes",                 limit: 65535
    t.date     "expiringDate"
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.integer  "article_id",                                                  null: false
    t.integer  "transportDocument_id"
    t.integer  "transport_document_id"
    t.string   "barcode"
    t.integer  "position_code_id"
    t.index ["article_id"], name: "index_items_on_article_id", using: :btree
    t.index ["position_code_id"], name: "index_items_on_position_code_id", using: :btree
    t.index ["transportDocument_id"], name: "index_items_on_transportDocument_id", using: :btree
    t.index ["transport_document_id"], name: "index_items_on_transport_document_id", using: :btree
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

  create_table "people", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",                     default: "", null: false
    t.string   "surname",                  default: "", null: false
    t.text     "notes",      limit: 65535
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "position_codes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "vehicle_models", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.integer  "type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "manufacturer_id"
    t.index ["manufacturer_id"], name: "index_vehicle_models_on_manufacturer_id", using: :btree
  end

  create_table "vehicles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.boolean  "dismissed",         default: false
    t.date     "registration_date"
    t.string   "initial_serial"
    t.integer  "mileage"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "property_id"
    t.integer  "model_id"
    t.index ["model_id"], name: "index_vehicles_on_model_id", using: :btree
    t.index ["property_id"], name: "index_vehicles_on_property_id", using: :btree
  end

  add_foreign_key "articles", "companies", column: "manufacturer_id"
  add_foreign_key "articles", "position_codes"
  add_foreign_key "articles", "users", column: "created_by_id"
  add_foreign_key "item_relations", "items"
  add_foreign_key "item_relations", "offices"
  add_foreign_key "item_relations", "vehicles"
  add_foreign_key "items", "articles"
  add_foreign_key "items", "position_codes"
  add_foreign_key "items", "transport_documents"
  add_foreign_key "order_articles", "articles"
  add_foreign_key "order_articles", "orders"
  add_foreign_key "orders", "companies", column: "supplier_id"
  add_foreign_key "orders", "users", column: "created_by_id"
  add_foreign_key "transport_documents", "companies", column: "receiver_id"
  add_foreign_key "transport_documents", "companies", column: "subvector_id"
  add_foreign_key "transport_documents", "companies", column: "vector_id"
  add_foreign_key "transport_documents", "orders"
  add_foreign_key "vehicle_models", "companies", column: "manufacturer_id"
  add_foreign_key "vehicles", "companies", column: "property_id"
  add_foreign_key "vehicles", "vehicle_models", column: "model_id"
end
