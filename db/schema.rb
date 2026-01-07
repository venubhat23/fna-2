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

ActiveRecord::Schema[8.0].define(version: 2026_01_06_015013) do
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
    t.bigint "broker_id"
    t.index ["broker_id"], name: "index_agency_codes_on_broker_id"
  end

  create_table "banners", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "redirect_link"
    t.date "display_start_date"
    t.date "display_end_date"
    t.string "display_location"
    t.boolean "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "display_order", default: 0
    t.index ["display_order"], name: "index_banners_on_display_order"
  end

  create_table "brokers", force: :cascade do |t|
    t.string "name", null: false
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "insurance_company_id"
    t.index ["insurance_company_id"], name: "index_brokers_on_insurance_company_id"
    t.index ["name"], name: "index_brokers_on_name"
    t.index ["status"], name: "index_brokers_on_status"
  end

  create_table "client_requests", force: :cascade do |t|
    t.string "ticket_number", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone_number", null: false
    t.text "description", null: false
    t.string "status", default: "pending"
    t.string "priority", default: "medium"
    t.string "subject"
    t.string "request_type"
    t.datetime "submitted_at", null: false
    t.text "admin_response"
    t.datetime "resolved_at"
    t.bigint "resolved_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_client_requests_on_email"
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
    t.bigint "payout_id"
    t.string "lead_id"
    t.boolean "invoiced", default: false
    t.index ["lead_id"], name: "index_commission_payouts_on_lead_id"
    t.index ["payout_date"], name: "index_commission_payouts_on_payout_date"
    t.index ["payout_id"], name: "index_commission_payouts_on_payout_id"
    t.index ["payout_to", "status"], name: "idx_commission_payouts_payout_to_status"
    t.index ["payout_to", "status"], name: "index_commission_payouts_on_payout_to_and_status"
    t.index ["policy_type", "policy_id", "status"], name: "idx_commission_payouts_policy_status"
    t.index ["policy_type", "policy_id"], name: "idx_commission_payouts_policy"
    t.index ["policy_type", "policy_id"], name: "index_commission_payouts_on_policy_type_and_policy_id"
    t.index ["status"], name: "idx_commission_payouts_status"
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

  create_table "customer_documents", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "document_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_customer_documents_on_customer_id"
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
    t.integer "policies_count", default: 0, null: false
    t.integer "sub_agent_id"
    t.string "lead_id"
    t.index ["created_at"], name: "index_customers_on_created_at"
    t.index ["customer_type", "created_at"], name: "index_customers_on_customer_type_and_created_at"
    t.index ["customer_type", "status"], name: "index_customers_on_customer_type_and_status"
    t.index ["customer_type"], name: "index_customers_on_customer_type"
    t.index ["email"], name: "index_customers_on_email"
    t.index ["lead_id"], name: "index_customers_on_lead_id", unique: true
    t.index ["mobile"], name: "index_customers_on_mobile"
    t.index ["pan_number"], name: "index_customers_on_pan_number"
    t.index ["status", "created_at"], name: "index_customers_on_status_and_created_at"
    t.index ["status"], name: "index_customers_on_status"
    t.index ["sub_agent_id"], name: "index_customers_on_sub_agent_id"
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
    t.boolean "invoiced", default: false
    t.index ["distributor_id", "status"], name: "index_distributor_payouts_on_distributor_id_and_status"
    t.index ["distributor_id"], name: "index_distributor_payouts_on_distributor_id"
    t.index ["policy_type", "policy_id"], name: "index_distributor_payouts_on_policy_type_and_policy_id"
    t.index ["status"], name: "index_distributor_payouts_on_status"
  end

  create_table "distributors", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "middle_name"
    t.string "last_name", null: false
    t.string "mobile", null: false
    t.string "email", null: false
    t.integer "role_id", null: false
    t.integer "state_id"
    t.integer "city_id"
    t.date "birth_date"
    t.string "gender"
    t.string "pan_no"
    t.string "gst_no"
    t.string "company_name"
    t.text "address"
    t.string "bank_name"
    t.string "account_no"
    t.string "ifsc_code"
    t.string "account_holder_name"
    t.string "account_type"
    t.string "upi_id"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "affiliate_count", default: 0, null: false
    t.index ["email"], name: "index_distributors_on_email", unique: true
    t.index ["mobile"], name: "index_distributors_on_mobile", unique: true
    t.index ["role_id"], name: "index_distributors_on_role_id"
    t.index ["status"], name: "index_distributors_on_status"
  end

  create_table "documents", force: :cascade do |t|
    t.string "document_type"
    t.string "documentable_type", null: false
    t.bigint "documentable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.text "description"
    t.string "uploaded_by"
    t.index ["documentable_type", "documentable_id"], name: "index_documents_on_documentable"
  end

  create_table "family_members", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "first_name"
    t.date "birth_date"
    t.integer "age"
    t.string "height"
    t.string "weight"
    t.string "gender"
    t.string "relationship"
    t.string "pan_no"
    t.string "mobile"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "middle_name"
    t.string "last_name"
    t.string "height_feet"
    t.decimal "weight_kg", precision: 5, scale: 2
    t.text "additional_information"
    t.index ["customer_id"], name: "index_family_members_on_customer_id"
  end

  create_table "health_insurance_members", force: :cascade do |t|
    t.bigint "health_insurance_id", null: false
    t.string "member_name"
    t.integer "age"
    t.string "relationship"
    t.decimal "sum_insured"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["health_insurance_id"], name: "index_health_insurance_members_on_health_insurance_id"
  end

  create_table "health_insurances", force: :cascade do |t|
    t.bigint "policy_id"
    t.string "insurance_type"
    t.string "claim_process"
    t.decimal "main_agent_commission_percent"
    t.decimal "main_agent_commission_amount"
    t.decimal "main_agent_tds_percent"
    t.decimal "main_agent_tds_amount"
    t.string "reference_by_name"
    t.string "broker_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "customer_id"
    t.bigint "sub_agent_id"
    t.bigint "agency_code_id"
    t.bigint "broker_id"
    t.string "policy_holder"
    t.string "insurance_company_name"
    t.string "plan_name"
    t.string "policy_number"
    t.date "policy_booking_date"
    t.date "policy_start_date"
    t.date "policy_end_date"
    t.integer "policy_term"
    t.string "payment_mode"
    t.decimal "sum_insured"
    t.decimal "net_premium"
    t.decimal "gst_percentage"
    t.decimal "total_premium"
    t.decimal "main_agent_commission_percentage"
    t.decimal "commission_amount"
    t.decimal "tds_percentage"
    t.decimal "tds_amount"
    t.decimal "after_tds_value"
    t.string "policy_type"
    t.date "installment_autopay_start_date"
    t.date "installment_autopay_end_date"
    t.text "notification_dates"
    t.boolean "is_customer_added", default: false
    t.boolean "is_agent_added", default: false
    t.boolean "is_admin_added", default: false
    t.boolean "product_through_dr", default: false
    t.boolean "main_agent_commission_received", default: false
    t.string "main_agent_commission_transaction_id"
    t.date "main_agent_commission_paid_date"
    t.text "main_agent_commission_notes"
    t.string "lead_id"
    t.bigint "distributor_id"
    t.bigint "investor_id"
    t.decimal "ambassador_commission_percentage"
    t.decimal "ambassador_commission_amount"
    t.decimal "ambassador_tds_percentage"
    t.decimal "ambassador_tds_amount"
    t.decimal "ambassador_after_tds_value"
    t.decimal "sub_agent_commission_percentage"
    t.decimal "sub_agent_commission_amount"
    t.decimal "sub_agent_tds_percentage"
    t.decimal "sub_agent_tds_amount"
    t.decimal "sub_agent_after_tds_value"
    t.decimal "investor_commission_percentage"
    t.decimal "investor_commission_amount"
    t.decimal "investor_tds_percentage"
    t.decimal "investor_tds_amount"
    t.decimal "investor_after_tds_value"
    t.decimal "company_expenses_percentage"
    t.decimal "total_distribution_percentage"
    t.decimal "profit_percentage"
    t.decimal "profit_amount"
    t.boolean "policy_added_by_admin", default: false
    t.index ["agency_code_id"], name: "index_health_insurances_on_agency_code_id"
    t.index ["broker_id"], name: "index_health_insurances_on_broker_id"
    t.index ["created_at"], name: "idx_health_insurances_created_at"
    t.index ["customer_id"], name: "index_health_insurances_on_customer_id"
    t.index ["distributor_id"], name: "index_health_insurances_on_distributor_id"
    t.index ["investor_id"], name: "index_health_insurances_on_investor_id"
    t.index ["lead_id"], name: "index_health_insurances_on_lead_id", unique: true
    t.index ["policy_id"], name: "index_health_insurances_on_policy_id"
    t.index ["sub_agent_id"], name: "index_health_insurances_on_sub_agent_id"
  end

  create_table "indian_locations", force: :cascade do |t|
    t.string "state", null: false
    t.string "city", null: false
    t.string "district"
    t.string "pincode"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_indian_locations_on_is_active"
    t.index ["state", "city"], name: "index_indian_locations_on_state_and_city", unique: true
    t.index ["state"], name: "index_indian_locations_on_state"
  end

  create_table "insurance_companies", force: :cascade do |t|
    t.string "name"
    t.boolean "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
    t.string "contact_person"
    t.string "email"
    t.string "mobile"
    t.text "address"
  end
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
  create_table "payouts", force: :cascade do |t|
    t.string "policy_type"
    t.integer "policy_id"
    t.integer "customer_id"
    t.decimal "total_commission_amount"
    t.string "status"
    t.date "payout_date"
    t.string "processed_by"
    t.datetime "processed_at"
    t.text "notes"
    t.string "reference_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "main_agent_percentage", precision: 8, scale: 2
    t.decimal "main_agent_commission_amount", precision: 10, scale: 2
    t.integer "main_agent_commission_id"
    t.decimal "affiliate_percentage", precision: 8, scale: 2
    t.decimal "affiliate_commission_amount", precision: 10, scale: 2
    t.integer "affiliate_commission_id"
    t.decimal "ambassador_percentage", precision: 8, scale: 2
    t.decimal "ambassador_commission_amount", precision: 10, scale: 2
    t.integer "ambassador_commission_id"
    t.decimal "investor_percentage", precision: 8, scale: 2
    t.decimal "investor_commission_amount", precision: 10, scale: 2
    t.integer "investor_commission_id"
    t.decimal "company_expense_percentage", precision: 8, scale: 2
    t.decimal "company_expense_amount", precision: 10, scale: 2
    t.integer "company_expense_commission_id"
    t.text "commission_summary"
    t.decimal "net_premium"
    t.boolean "main_agent_commission_received"
    t.string "main_agent_commission_transaction_id"
    t.date "main_agent_commission_paid_date"
    t.index ["affiliate_commission_id"], name: "index_payouts_on_affiliate_commission_id"
    t.index ["ambassador_commission_id"], name: "index_payouts_on_ambassador_commission_id"
    t.index ["company_expense_commission_id"], name: "index_payouts_on_company_expense_commission_id"
    t.index ["investor_commission_id"], name: "index_payouts_on_investor_commission_id"
    t.index ["main_agent_commission_id"], name: "index_payouts_on_main_agent_commission_id"
    t.index ["policy_type", "policy_id"], name: "idx_payouts_policy"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "module_name", limit: 50, null: false
    t.string "action_type", limit: 20, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_type"], name: "index_permissions_on_action_type"
    t.index ["module_name", "action_type"], name: "index_permissions_on_module_name_and_action_type", unique: true
    t.index ["module_name"], name: "index_permissions_on_module_name"
  end

  create_table "policies", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "user_id", null: false
    t.bigint "insurance_company_id", null: false
    t.bigint "agency_broker_id", null: false
    t.string "policy_number"
    t.string "policy_type"
    t.string "insurance_type"
    t.string "plan_name"
    t.string "payment_mode"
    t.date "policy_booking_date"
    t.date "policy_start_date"
    t.date "policy_end_date"
    t.integer "policy_term_years"
    t.date "risk_start_date"
    t.decimal "sum_insured"
    t.decimal "net_premium"
    t.decimal "gst_percentage"
    t.decimal "total_premium"
    t.decimal "bonus"
    t.decimal "fund"
    t.text "note"
    t.boolean "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_broker_id"], name: "index_policies_on_agency_broker_id"
    t.index ["customer_id", "created_at"], name: "index_policies_on_customer_id_and_created_at"
    t.index ["customer_id"], name: "index_policies_on_customer_id"
    t.index ["insurance_company_id"], name: "index_policies_on_insurance_company_id"
    t.index ["user_id"], name: "index_policies_on_user_id"
  end

  create_table "product_categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "category_type", null: false
    t.bigint "parent_id"
    t.boolean "is_active", default: true
    t.string "image_url"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_type"], name: "index_product_categories_on_category_type"
    t.index ["is_active"], name: "index_product_categories_on_is_active"
    t.index ["parent_id", "name"], name: "index_product_categories_on_parent_id_and_name", unique: true
    t.index ["parent_id"], name: "index_product_categories_on_parent_id"
  end

  create_table "product_locations", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "location", null: false
    t.boolean "is_available", default: true
    t.text "availability_notes"
    t.decimal "location_specific_price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_available"], name: "index_product_locations_on_is_available"
    t.index ["product_id", "location"], name: "index_product_locations_on_product_id_and_location", unique: true
    t.index ["product_id"], name: "index_product_locations_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "product_type", null: false
    t.string "sku"
    t.decimal "price", precision: 10, scale: 2
    t.string "status", default: "active"
    t.bigint "product_category_id", null: false
    t.string "insurance_company"
    t.string "plan_name"
    t.integer "min_age"
    t.integer "max_age"
    t.decimal "min_sum_insured", precision: 12, scale: 2
    t.decimal "max_sum_insured", precision: 12, scale: 2
    t.json "features"
    t.json "benefits"
    t.string "meta_title"
    t.text "meta_description"
    t.string "slug"
    t.boolean "featured", default: false
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["featured"], name: "index_products_on_featured"
    t.index ["product_category_id"], name: "index_products_on_product_category_id"
    t.index ["product_type"], name: "index_products_on_product_type"
    t.index ["sku"], name: "index_products_on_sku", unique: true, where: "(sku IS NOT NULL)"
    t.index ["slug"], name: "index_products_on_slug", unique: true, where: "(slug IS NOT NULL)"
    t.index ["status"], name: "index_products_on_status"
  end

  create_table "role_permissions", force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "permission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "idx_role_permissions_permission"
    t.index ["role_id", "permission_id"], name: "idx_role_permissions_unique", unique: true
    t.index ["role_id"], name: "idx_role_permissions_role"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.text "description"
    t.boolean "status", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
    t.index ["status"], name: "index_roles_on_status"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "sub_agent_documents", force: :cascade do |t|
    t.bigint "sub_agent_id", null: false
    t.string "document_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sub_agent_id", "document_type"], name: "index_sub_agent_documents_on_sub_agent_id_and_document_type"
    t.index ["sub_agent_id"], name: "index_sub_agent_documents_on_sub_agent_id"
  end

  create_table "sub_agents", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "middle_name"
    t.string "last_name", null: false
    t.string "mobile", null: false
    t.string "email", null: false
    t.integer "role_id", null: false
    t.integer "state_id"
    t.integer "city_id"
    t.date "birth_date"
    t.string "gender"
    t.string "pan_no"
    t.string "gst_no"
    t.string "company_name"
    t.text "address"
    t.string "bank_name"
    t.string "account_no"
    t.string "ifsc_code"
    t.string "account_holder_name"
    t.string "account_type"
    t.string "upi_id"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.bigint "distributor_id"
    t.string "plain_password"
    t.string "original_password"
    t.index ["distributor_id"], name: "index_sub_agents_on_distributor_id"
    t.index ["email"], name: "index_sub_agents_on_email", unique: true
    t.index ["mobile"], name: "index_sub_agents_on_mobile", unique: true
    t.index ["role_id"], name: "index_sub_agents_on_role_id"
    t.index ["status"], name: "index_sub_agents_on_status"
  end

  create_table "system_settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.text "description"
    t.string "setting_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "default_main_agent_commission", precision: 5, scale: 2
    t.decimal "default_affiliate_commission", precision: 5, scale: 2
    t.decimal "default_ambassador_commission", precision: 5, scale: 2
    t.decimal "default_company_expenses", precision: 5, scale: 2
    t.index ["key"], name: "index_system_settings_on_key", unique: true
  end

  create_table "tax_services", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "service_type"
    t.string "financial_year"
    t.date "filing_date"
    t.decimal "amount"
    t.boolean "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_tax_services_on_customer_id"
  end

  create_table "travel_packages", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "travel_type"
    t.string "destination"
    t.date "travel_date"
    t.date "return_date"
    t.decimal "package_amount"
    t.boolean "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_travel_packages_on_customer_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "status", default: true, null: false
    t.integer "display_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["display_order"], name: "index_user_roles_on_display_order"
    t.index ["name"], name: "index_user_roles_on_name", unique: true
    t.index ["status"], name: "index_user_roles_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "mobile"
    t.string "pan_number"
    t.string "gst_number"
    t.date "date_of_birth"
    t.string "gender"
    t.string "height"
    t.string "weight"
    t.string "education"
    t.string "marital_status"
    t.string "occupation"
    t.string "job_name"
    t.string "type_of_duty"
    t.decimal "annual_income"
    t.string "birth_place"
    t.string "address"
    t.string "state"
    t.string "city"
    t.string "user_type"
    t.string "role"
    t.boolean "status"
    t.text "additional_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.bigint "role_id"
    t.bigint "user_role_id"
    t.string "plain_password"
    t.boolean "admin", default: false
    t.string "original_password"
    t.text "sidebar_permissions"
    t.string "role_name"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "idx_users_role_id"
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["user_role_id"], name: "index_users_on_user_role_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agency_codes", "brokers"
  add_foreign_key "brokers", "insurance_companies"
  add_foreign_key "client_requests", "users", column: "resolved_by_id"
  add_foreign_key "commission_payouts", "payouts"
  add_foreign_key "corporate_members", "customers"
  add_foreign_key "customer_documents", "customers"
  add_foreign_key "customers", "sub_agents"
  add_foreign_key "distributor_assignments", "distributors"
  add_foreign_key "distributor_assignments", "sub_agents"
  add_foreign_key "distributor_documents", "distributors"
  add_foreign_key "distributor_payouts", "distributors"
  add_foreign_key "family_members", "customers"
  add_foreign_key "health_insurance_members", "health_insurances"
  add_foreign_key "health_insurances", "agency_codes"
  add_foreign_key "health_insurances", "brokers"
  add_foreign_key "health_insurances", "customers"
  add_foreign_key "health_insurances", "distributors"
  add_foreign_key "health_insurances", "investors"
  add_foreign_key "health_insurances", "policies"
  add_foreign_key "health_insurances", "sub_agents"
  add_foreign_key "investments", "customers"
  add_foreign_key "investor_documents", "investors"
  add_foreign_key "life_insurance_bank_details", "life_insurances"
  add_foreign_key "life_insurance_documents", "life_insurances"
  add_foreign_key "life_insurance_nominees", "life_insurances"
  add_foreign_key "life_insurances", "agency_codes"
  add_foreign_key "life_insurances", "brokers"
  add_foreign_key "life_insurances", "customers"
  add_foreign_key "life_insurances", "distributors"
  add_foreign_key "life_insurances", "investors"
  add_foreign_key "life_insurances", "sub_agents"
  add_foreign_key "loans", "customers"
  add_foreign_key "motor_insurances", "agency_codes"
  add_foreign_key "motor_insurances", "brokers"
  add_foreign_key "motor_insurances", "customers"
  add_foreign_key "motor_insurances", "distributors"
  add_foreign_key "motor_insurances", "investors"
  add_foreign_key "motor_insurances", "sub_agents"
  add_foreign_key "other_insurances", "distributors"
  add_foreign_key "other_insurances", "investors"
  add_foreign_key "other_insurances", "policies"
  add_foreign_key "payout_distributions", "commission_receipts"
  add_foreign_key "policies", "agency_brokers"
  add_foreign_key "policies", "customers"
  add_foreign_key "policies", "insurance_companies"
  add_foreign_key "policies", "users"
  add_foreign_key "product_categories", "product_categories", column: "parent_id"
  add_foreign_key "product_locations", "products"
  add_foreign_key "products", "product_categories"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "sub_agent_documents", "sub_agents"
  add_foreign_key "sub_agents", "distributors"
  add_foreign_key "tax_services", "customers"
  add_foreign_key "travel_packages", "customers"
  add_foreign_key "users", "roles"
  add_foreign_key "users", "user_roles"
end
