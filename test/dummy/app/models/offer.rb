class Offer < ApplicationRecord
  money_attribute :price, currency: 'USD'
end
