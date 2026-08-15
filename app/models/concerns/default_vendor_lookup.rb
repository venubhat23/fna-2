module DefaultVendorLookup
  extend ActiveSupport::Concern

  private

  def get_or_create_default_vendor
    Vendor.find_or_create_by(name: 'System Default') do |vendor|
      vendor.email = 'system@default.com'
      vendor.phone = '0000000000'
      vendor.address = 'System Generated'
      vendor.payment_type = 'Cash'
      vendor.status = true
    end
  end
end
