class FinancialTransaction < ApplicationRecord
  money_attribute :value, currency: 'USD', mapping: {amount: :amount, currency: :currency}
end
