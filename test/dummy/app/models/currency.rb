class Currency < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :subunit, presence: true, numericality: { in: 0..16, only_integer: true }
  validates :symbol, presence: true
end
