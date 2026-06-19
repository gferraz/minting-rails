# frozen_string_literal: true

require 'test_helper'

module Mint
  class AmountOnlyAttributeTest < ActiveSupport::TestCase
    test 'requires a callable' do
      assert_raises(ArgumentError) do
        Class.new(ApplicationRecord) do
          self.table_name = 'financial_transactions'
          money_attribute :amount, currency: :not_callable
        end
      end
    end

    test 'callable provides currency code' do
      klass = Class.new(ApplicationRecord) do
        self.table_name = 'financial_transactions'
        money_attribute :amount, currency: ->(_r) { 'USD' }
      end

      transaction = klass.new(amount: 45.34.dollars)

      assert_equal 45.34.dollars, transaction.amount
      assert_equal 'USD', transaction.read_attribute(:_amount_currency_code)
    end

    test 'callable reads currency code from record' do
      usd = ::Currency.create!(code: 'USD', subunit: 2, symbol: '$')

      klass = Class.new(ApplicationRecord) do
        self.table_name = 'financial_transactions'
        money_attribute :amount, currency: ->(r) { ::Currency.find_by(id: r.currency_id)&.code }
      end

      transaction = klass.new(amount: 45.34.dollars, currency_id: usd.id)

      assert_equal 45.34.dollars, transaction.amount
    end

    test 'callable is invoked on after_find' do
      usd = ::Currency.create!(code: 'USD', subunit: 2, symbol: '$')

      callable_called = 0
      code_callable = lambda { |r|
        callable_called += 1
        ::Currency.find_by(id: r.currency_id)&.code
      }

      klass = Class.new(ApplicationRecord) do
        self.table_name = 'financial_transactions'
        money_attribute :amount, currency: code_callable
      end

      transaction = klass.create!(amount: 45.34.dollars, currency_id: usd.id)
      reloaded = transaction.reload

      assert_equal 45.34.dollars, reloaded.amount
      assert_equal 1, callable_called
    end

    test 'callable restores money value after reload' do
      usd = ::Currency.create!(code: 'USD', subunit: 2, symbol: '$')

      klass = Class.new(ApplicationRecord) do
        self.table_name = 'financial_transactions'
        money_attribute :amount, currency: ->(r) { ::Currency.find_by(id: r.currency_id)&.code }
      end

      transaction = klass.create!(amount: 45.34.dollars, currency_id: usd.id)
      reloaded = transaction.reload

      assert_equal 45.34.dollars, reloaded.amount
    end

    test 'callable validates non-callable argument' do
      error = assert_raises(ArgumentError) do
        Class.new(ApplicationRecord) do
          self.table_name = 'financial_transactions'
          money_attribute :amount, currency: 42
        end
      end
      assert_match(/currency:/, error.message)
    end

    test 'static currency code string' do
      klass = Class.new(ApplicationRecord) do
        self.table_name = 'financial_transactions'
        money_attribute :amount, currency: 'USD'
      end

      transaction = klass.new(amount: 45.34.dollars)

      assert_equal 45.34.dollars, transaction.amount
      assert_equal 'USD', transaction.read_attribute(:_amount_currency_code)
    end

    test 'static currency with number assignment' do
      klass = Class.new(ApplicationRecord) do
        self.table_name = 'financial_transactions'
        money_attribute :amount, currency: 'USD'
      end

      transaction = klass.new(amount: 12.34)

      assert_equal 12.34.dollars, transaction.amount
    end
  end
end
