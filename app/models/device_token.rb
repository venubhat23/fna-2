class DeviceToken < ApplicationRecord
  belongs_to :customer
  belongs_to :delivery_person
end
