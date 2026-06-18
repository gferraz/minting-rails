# frozen_string_literal: true

require 'test_helper'

module Mint
  class CurrencyViaTest < ActiveSupport::TestCase
    test 'currency_via writes fractional amount and virtual currency code' do
      transaction = FinancialTransaction.new(amount: 45.34.dollars)

      assert_equal 4534, transaction.read_attribute(:amount)
      assert_equal 'USD', transaction.read_attribute(:_amount_currency_code)
    end

    test 'currency_via saves and reloads using currency association' do
      usd = ::Currency.create!(code: 'USD', subunit: 2, symbol: '$')
      ::Currency.create!(code: 'EUR', subunit: 2, symbol: '€')

      transaction = FinancialTransaction.new(amount: 45.34.dollars)
      transaction.currency = usd
      transaction.save!

      assert_equal 45.34.dollars, transaction.amount
      assert_equal 'USD', transaction.currency.code
      assert_equal 4534, transaction.read_attribute(:amount)

      reloaded = FinancialTransaction.find(transaction.id)

      assert_equal 45.34.dollars, reloaded.amount
      assert_equal 'USD', reloaded.currency.code
    end

    test 'currency_via writes integer amount as fractional' do
      usd = ::Currency.create!(code: 'USD', subunit: 2, symbol: '$')

      transaction = FinancialTransaction.new(amount: 54.32.dollars)

      assert_equal 5432, transaction.read_attribute(:amount)
      assert_equal 'USD', transaction.read_attribute(:_amount_currency_code)

      transaction.currency = usd
      transaction.save!
      assert_equal 'USD', transaction.currency.code

      reloaded = transaction.reload
      assert_equal 54.32.dollars, reloaded.amount
    end

    test 'currency_via reloads with correct Money via after_find' do
      usd = ::Currency.create!(code: 'USD', subunit: 2, symbol: '$')

      transaction = FinancialTransaction.new(amount: 45.34.dollars)
      transaction.currency = usd
      transaction.save!
      reloaded = transaction.reload

      assert_equal 45.34.dollars, reloaded.amount
      assert_equal 'USD', reloaded.currency.code
    end

    test 'currency_via with callable reads currency code' do
      ::Currency.create!(code: 'USD', subunit: 2, symbol: '$')

      klass = Class.new(ApplicationRecord) do
        self.table_name = 'financial_transactions'
        money_attribute :amount, currency_via: ->(_r) { 'USD' }
      end

      transaction = klass.new(amount: 45.34.dollars)

      assert_equal 45.34.dollars, transaction.amount
      assert_equal 'USD', transaction.read_attribute(:_amount_currency_code)
    end

    test 'currency_via with callable restores code on reload' do
      usd = ::Currency.create!(code: 'USD', subunit: 2, symbol: '$')

      callable_called = 0
      code_callable = lambda { |r|
        callable_called += 1
        ::Currency.find_by(id: r.currency_id)&.code
      }

      klass = Class.new(ApplicationRecord) do
        self.table_name = 'financial_transactions'
        money_attribute :amount, currency_via: code_callable
      end

      transaction = klass.create!(amount: 45.34.dollars, currency_id: usd.id)
      reloaded = transaction.reload

      assert_equal 45.34.dollars, reloaded.amount
      assert_equal 1, callable_called # called during reload's after_find
    end
  end
end
