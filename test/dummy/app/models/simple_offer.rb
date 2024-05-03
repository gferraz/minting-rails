class SimpleOffer < ApplicationRecord
  money_attribute :price, currency: 'USD'
  money_attribute :discount, currency: 'USD'
end
