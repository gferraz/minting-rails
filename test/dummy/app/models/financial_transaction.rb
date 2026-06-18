class FinancialTransaction < ApplicationRecord
  belongs_to :currency

  money_attribute :amount, currency: 'USD'

end
