class AddIndexesForLeadsMobileLookups < ActiveRecord::Migration[8.0]
  def change
    # Api::V1::Mobile::AgentController's leads/add_lead/get_leads_statistics actions
    # hit the leads table constantly and it currently has exactly one index
    # (affiliate_id). Every other lookup here is a full table scan:
    #   - add_lead: Lead.find_by(contact_number:) / find_by(email:) - duplicate check
    #     on every single lead creation
    #   - leads: by_stage/by_product_subcategory/by_source filter on these columns
    #   - get_leads_statistics: Lead.group(:current_stage).count,
    #     Lead.group(:lead_source).count
    #
    # NOTE: the code (Lead#recent scope, Lead#created_date=, this file's
    # get_leads_statistics this_month_leads filter) references a `created_date`
    # column that does not exist in this schema (db/schema.rb only has
    # created_at/updated_at on leads) - those call sites will raise
    # "column leads.created_date does not exist" as-is, independent of indexing,
    # so no index is added for it here.
    #
    # NOT run yet - written for review, same as the customers/delivery_people
    # index migrations. Added as plain (non-unique) indexes: contact_number/email
    # uniqueness is enforced at the model validation layer, not verified against
    # live data here.
    add_index :leads, :contact_number
    add_index :leads, :email
    add_index :leads, :current_stage
    add_index :leads, :lead_source
  end
end
