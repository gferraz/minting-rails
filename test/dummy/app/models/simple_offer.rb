class SimpleOffer < ApplicationRecord
  money_attribute :price
  money_attribute :discount
end
