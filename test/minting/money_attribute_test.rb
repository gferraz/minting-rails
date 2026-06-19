# frozen_string_literal: true

require 'test_helper'

module Mint
  class MoneyAttributeRoutingTest < ActiveSupport::TestCase
    test 'routes to amount_currency_attribute when currency column exists' do
      offer = Offer.new(price: 12.dollars)

      assert_equal 12.dollars, offer.price
      assert_equal 12, offer.price_amount
      assert_equal 'USD', offer.price_currency
    end

    test 'routes to amount_currency_attribute when currency_via is given' do
      usd = ::Currency.create!(code: 'USD', subunit: 2, symbol: '$')

      transaction = FinancialTransaction.new(amount: 45.34.dollars)
      transaction.currency = usd
      transaction.save!

      assert_equal 45.34.dollars, transaction.amount
      assert_equal 'USD', transaction.read_attribute(:_amount_currency_code)
    end

    test 'routes to amount_currency_attribute when mapping is given' do
      klass = Class.new(ApplicationRecord) do
        self.table_name = 'offers'

        money_attribute :cost, mapping: {
          amount: :price_amount,
          currency: :price_currency
        }
      end

      offer = klass.new(cost: 19.euros)

      assert_equal 19.euros, offer.cost
      assert_equal 19, offer.price_amount
      assert_equal 'EUR', offer.price_currency
    end

    test 'routes to amount_only_attribute when no currency column exists' do
      klass = Class.new(ApplicationRecord) do
        self.table_name = 'financial_transactions'

        money_attribute :amount, currency: 'USD'
      end

      transaction = klass.new(amount: 45.34.dollars)

      assert_equal 45.34.dollars, transaction.amount
      assert_equal 'USD', transaction.read_attribute(:_amount_currency_code)
    end

    test 'routes to amount_only_attribute with callable currency' do
      klass = Class.new(ApplicationRecord) do
        self.table_name = 'financial_transactions'

        money_attribute :amount, currency: ->(_r) { 'USD' }
      end

      transaction = klass.new(amount: 45.34.dollars)

      assert_equal 45.34.dollars, transaction.amount
      assert_equal 'USD', transaction.read_attribute(:_amount_currency_code)
    end

    test 'raises ArgumentError when no currency column and no currency given' do
      assert_raises(ArgumentError) do
        Class.new(ApplicationRecord) do
          self.table_name = 'financial_transactions'

          money_attribute :amount
        end
      end
    end
  end
end
