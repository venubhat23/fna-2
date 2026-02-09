# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_08_153931) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agency_brokers", force: :cascade do |t|
    t.string "broker_name"
    t.string "broker_code"
    t.string "agency_code"
    t.boolean "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "agency_codes", force: :cascade do |t|
    t.string "insurance_type"
    t.string "company_name"
    t.string "agent_name"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "banners", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "redirect_link"
    t.date "display_start_date"
    t.date "display_end_date"
    t.string "display_location"
    t.boolean "status", default: true
    t.integer "display_order", default: 0
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["display_location"], name: "index_banners_on_display_location"
    t.index ["display_order"], name: "index_banners_on_display_order"
    t.index ["status"], name: "index_banners_on_status"
  end

  create_table "booking_invoices", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "customer_id", null: false
    t.string "invoice_number"
    t.datetime "invoice_date"
    t.datetime "due_date"
    t.decimal "subtotal"
    t.decimal "tax_amount"
    t.decimal "discount_amount"
    t.decimal "total_amount"
    t.integer "payment_status"
    t.integer "status"
    t.text "notes"
    t.text "invoice_items"
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_booking_invoices_on_booking_id"
    t.index ["customer_id"], name: "index_booking_invoices_on_customer_id"
    t.index ["invoice_number"], name: "index_booking_invoices_on_invoice_number", unique: true
  end

  create_table "booking_items", force: :cascade do |t|
    t.integer "booking_id"
    t.integer "product_id"
    t.integer "quantity"
    t.decimal "price"
    t.decimal "total"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "booking_schedules", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "product_id", null: false
    t.string "schedule_type"
    t.string "frequency"
    t.date "start_date"
    t.date "end_date"
    t.integer "quantity"
    t.time "delivery_time"
    t.text "delivery_address"
    t.string "pincode"
    t.decimal "latitude"
    t.decimal "longitude"
    t.string "status"
    t.date "next_booking_date"
    t.integer "total_bookings_generated"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_booking_schedules_on_customer_id"
    t.index ["product_id"], name: "index_booking_schedules_on_product_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.integer "customer_id"
    t.integer "user_id"
    t.string "booking_number"
    t.datetime "booking_date"
    t.string "status"
    t.string "payment_method"
    t.string "payment_status"
    t.decimal "subtotal"
    t.decimal "tax_amount"
    t.decimal "discount_amount"
    t.decimal "total_amount"
    t.text "notes"
    t.text "booking_items"
    t.string "customer_name"
    t.string "customer_email"
    t.string "customer_phone"
    t.text "delivery_address"
    t.boolean "invoice_generated"
    t.string "invoice_number"
    t.decimal "cash_received"
    t.decimal "change_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "booking_items_count", default: 0, null: false
    t.bigint "booking_schedule_id"
    t.string "stage"
    t.string "courier_service"
    t.string "tracking_number"
    t.decimal "shipping_charges", precision: 10, scale: 2
    t.date "expected_delivery_date"
    t.string "delivery_person"
    t.string "delivery_contact"
    t.string "delivered_to"
    t.datetime "delivery_time"
    t.integer "customer_satisfaction"
    t.string "processing_team"
    t.datetime "expected_completion_time"
    t.string "estimated_processing_time"
    t.string "estimated_delivery_time"
    t.decimal "package_weight", precision: 8, scale: 2
    t.string "package_dimensions"
    t.string "quality_status"
    t.string "cancellation_reason"
    t.string "return_reason"
    t.string "return_condition"
    t.decimal "refund_amount", precision: 10, scale: 2
    t.string "refund_method"
    t.text "transition_notes"
    t.text "stage_history"
    t.datetime "stage_updated_at"
    t.integer "stage_updated_by"
    t.bigint "store_id"
    t.index ["booking_schedule_id"], name: "index_bookings_on_booking_schedule_id"
    t.index ["courier_service"], name: "index_bookings_on_courier_service"
    t.index ["delivery_time"], name: "index_bookings_on_delivery_time"
    t.index ["expected_delivery_date"], name: "index_bookings_on_expected_delivery_date"
    t.index ["stage_updated_at"], name: "index_bookings_on_stage_updated_at"
    t.index ["stage_updated_by"], name: "index_bookings_on_stage_updated_by"
    t.index ["store_id"], name: "index_bookings_on_store_id"
    t.index ["tracking_number"], name: "index_bookings_on_tracking_number"
  end

  create_table "brokers", force: :cascade do |t|
    t.string "name", null: false
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_brokers_on_name"
    t.index ["status"], name: "index_brokers_on_status"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "image"
    t.boolean "status", default: true
    t.integer "display_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["display_order"], name: "index_categories_on_display_order"
    t.index ["status"], name: "index_categories_on_status"
  end

  create_table "client_requests", force: :cascade do |t|
    t.string "ticket_number", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone_number", null: false
    t.text "description", null: false
    t.string "status", default: "pending"
    t.string "priority", default: "medium"
    t.datetime "submitted_at", null: false
    t.text "admin_response"
    t.datetime "resolved_at"
    t.bigint "resolved_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stage"
    t.datetime "stage_updated_at"
    t.text "stage_history"
    t.integer "assignee_id"
    t.string "department"
    t.datetime "estimated_resolution_time"
    t.datetime "actual_resolution_time"
    t.index ["assignee_id"], name: "index_client_requests_on_assignee_id"
    t.index ["department"], name: "index_client_requests_on_department"
    t.index ["email"], name: "index_client_requests_on_email"
    t.index ["estimated_resolution_time"], name: "index_client_requests_on_estimated_resolution_time"
    t.index ["resolved_by_id"], name: "index_client_requests_on_resolved_by_id"
    t.index ["status"], name: "index_client_requests_on_status"
    t.index ["submitted_at"], name: "index_client_requests_on_submitted_at"
    t.index ["ticket_number"], name: "index_client_requests_on_ticket_number", unique: true
  end

  create_table "commission_payouts", force: :cascade do |t|
    t.string "policy_type"
    t.integer "policy_id"
    t.string "payout_to"
    t.decimal "payout_amount"
    t.date "payout_date"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transaction_id"
    t.string "payment_mode"
    t.string "reference_number"
    t.decimal "commission_amount_received", precision: 10, scale: 2
    t.decimal "distribution_percentage", precision: 5, scale: 2
    t.text "notes"
    t.string "processed_by"
    t.datetime "processed_at"
    t.index ["payout_date"], name: "index_commission_payouts_on_payout_date"
    t.index ["payout_to", "status"], name: "index_commission_payouts_on_payout_to_and_status"
    t.index ["policy_type", "policy_id"], name: "index_commission_payouts_on_policy_type_and_policy_id"
  end

  create_table "commission_receipts", force: :cascade do |t|
    t.string "policy_type", null: false
    t.integer "policy_id", null: false
    t.decimal "total_commission_received", precision: 12, scale: 2, null: false
    t.date "received_date", null: false
    t.string "insurance_company_name"
    t.string "insurance_company_reference"
    t.decimal "company_commission_percentage", precision: 5, scale: 2
    t.string "payment_mode"
    t.string "transaction_id"
    t.text "notes"
    t.string "received_by"
    t.boolean "auto_distributed", default: false
    t.datetime "distributed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auto_distributed"], name: "index_commission_receipts_on_auto_distributed"
    t.index ["policy_type", "policy_id"], name: "index_commission_receipts_on_policy_type_and_policy_id", unique: true
    t.index ["received_date"], name: "index_commission_receipts_on_received_date"
  end

  create_table "corporate_members", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "company_name"
    t.string "mobile"
    t.string "email"
    t.string "state"
    t.string "city"
    t.text "address"
    t.decimal "annual_income"
    t.string "pan_no"
    t.string "gst_no"
    t.text "additional_information"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_corporate_members_on_customer_id"
  end

  create_table "coupons", force: :cascade do |t|
    t.string "code"
    t.text "description"
    t.string "discount_type"
    t.decimal "discount_value"
    t.decimal "minimum_amount"
    t.decimal "maximum_discount"
    t.integer "usage_limit"
    t.integer "used_count"
    t.datetime "valid_from"
    t.datetime "valid_until"
    t.boolean "status"
    t.text "applicable_products"
    t.text "applicable_categories"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_coupons_on_code", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.string "customer_type"
    t.string "first_name"
    t.string "last_name"
    t.string "company_name"
    t.string "email"
    t.string "mobile"
    t.string "address"
    t.string "state"
    t.string "city"
    t.date "birth_date"
    t.integer "age"
    t.string "gender"
    t.string "height"
    t.string "weight"
    t.string "education"
    t.string "marital_status"
    t.string "occupation"
    t.string "job_name"
    t.string "type_of_duty"
    t.decimal "annual_income"
    t.string "pan_number"
    t.string "gst_number"
    t.string "birth_place"
    t.text "additional_info"
    t.boolean "status"
    t.string "added_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nominee_name"
    t.string "nominee_relation"
    t.date "nominee_date_of_birth"
    t.string "pincode"
    t.string "sub_agent", default: "Self"
    t.string "middle_name"
    t.string "height_feet"
    t.decimal "weight_kg", precision: 5, scale: 2
    t.string "business_job"
    t.string "business_name"
    t.text "additional_information"
    t.string "pan_no"
    t.string "gst_no"
    t.decimal "longitude", precision: 10, scale: 8
    t.decimal "latitude", precision: 10, scale: 8
    t.string "whatsapp_number"
    t.string "auto_generated_password"
    t.datetime "location_obtained_at"
    t.decimal "location_accuracy", precision: 8, scale: 2
    t.string "password_digest"
    t.index ["created_at"], name: "index_customers_on_created_at"
    t.index ["customer_type", "created_at"], name: "index_customers_on_customer_type_and_created_at"
    t.index ["customer_type", "status"], name: "index_customers_on_customer_type_and_status"
    t.index ["customer_type"], name: "index_customers_on_customer_type"
    t.index ["email"], name: "index_customers_on_email"
    t.index ["latitude", "longitude"], name: "index_customers_on_location"
    t.index ["mobile"], name: "index_customers_on_mobile"
    t.index ["pan_number"], name: "index_customers_on_pan_number"
    t.index ["status", "created_at"], name: "index_customers_on_status_and_created_at"
    t.index ["status"], name: "index_customers_on_status"
    t.index ["whatsapp_number"], name: "index_customers_on_whatsapp_number"
  end

  create_table "delivery_people", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "mobile"
    t.string "vehicle_type"
    t.string "vehicle_number"
    t.string "license_number"
    t.text "address"
    t.string "city"
    t.string "state"
    t.string "pincode"
    t.string "emergency_contact_name"
    t.string "emergency_contact_mobile"
    t.date "joining_date"
    t.decimal "salary"
    t.boolean "status"
    t.string "profile_picture"
    t.string "bank_name"
    t.string "account_no"
    t.string "ifsc_code"
    t.string "account_holder_name"
    t.text "delivery_areas"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "auto_generated_password"
  end

  create_table "delivery_rules", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "rule_type", null: false
    t.text "location_data"
    t.boolean "is_excluded", default: false
    t.integer "delivery_days"
    t.decimal "delivery_charge", precision: 8, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_delivery_rules_on_product_id"
    t.index ["rule_type"], name: "index_delivery_rules_on_rule_type"
  end

  create_table "distributor_assignments", force: :cascade do |t|
    t.bigint "distributor_id", null: false
    t.bigint "sub_agent_id", null: false
    t.datetime "assigned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["distributor_id"], name: "index_distributor_assignments_on_distributor_id"
    t.index ["sub_agent_id"], name: "index_distributor_assignments_on_sub_agent_id"
  end

  create_table "distributor_documents", force: :cascade do |t|
    t.bigint "distributor_id", null: false
    t.string "document_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["distributor_id"], name: "index_distributor_documents_on_distributor_id"
  end

  create_table "distributor_payouts", force: :cascade do |t|
    t.bigint "distributor_id", null: false
    t.string "policy_type"
    t.integer "policy_id"
    t.decimal "payout_amount", precision: 10, scale: 2
    t.date "payout_date"
    t.string "status", default: "pending"
    t.string "transaction_id"
    t.string "payment_mode"
    t.string "reference_number"
    t.text "notes"
    t.string "processed_by"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["distributor_id", "status"], name: "index_distributor_payouts_on_distributor_id_and_status"
    t.index ["distributor_id"], name: "index_distributor_payouts_on_distributor_id"
    t.index ["policy_type", "policy_id"], name: "index_distributor_payouts_on_policy_type_and_policy_id"
    t.index ["status"], name: "index_distributor_payouts_on_status"
  end
