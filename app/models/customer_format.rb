class CustomerFormat < ApplicationRecord
  belongs_to :customer
  belongs_to :product
  belongs_to :delivery_person
end
