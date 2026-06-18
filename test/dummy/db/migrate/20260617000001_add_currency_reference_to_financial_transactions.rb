class AddCurrencyReferenceToFinancialTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :financial_transactions, :currency, foreign_key: true
    remove_column :financial_transactions, :currency, :string
  end
end
