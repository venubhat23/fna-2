class AddIndexesForDeliveryPeopleLookups < ActiveRecord::Migration[8.0]
  def change
    # DeliveryPerson has no indexes at all beyond the primary key. email/mobile are
    # looked up on every mobile-app login (Api::V1::Mobile::AuthenticationController#login,
    # find_by(email:...) / find_by(mobile:...)) and are validated as unique at the model
    # level with no matching DB constraint - so lookups full-scan the table and uniqueness
    # isn't actually enforced under concurrent writes. status is filtered in a dozen+
    # admin call sites (DeliveryPerson.where(status: true)).
    #
    # NOT run yet - written for review. email/mobile are added as plain (non-unique)
    # indexes for now: adding `unique: true` could fail to apply if the live data already
    # has duplicates, which hasn't been checked (no DB access without separate approval).
    add_index :delivery_people, :email
    add_index :delivery_people, :mobile
    add_index :delivery_people, :status
  end
end
