# frozen_string_literal: true

require 'test_helper'

module Mint
  class MoneyAttributeTest < ActiveSupport::TestCase
    test 'Money attribute is enabled' do
      assert Offer.attribute :price
    end

    test 'aggregated money attribute updates mapped attributes' do
      offer = Offer.new(price: 12.dollars)

      assert_equal 12.dollars, offer.price
      assert_equal 12, offer.price_amount
      assert_equal 'USD', offer.price_currency
    end

    test 'aggregated money attribute parses any amount to the default currency' do
      offer = Offer.new(price: '12')

      assert_equal Mint.money(12, 'USD'), offer.price
      assert_equal 12, offer.price_amount
      assert_equal 'USD', offer.price_currency
    end

    test 'aggregated money attribute is saved correctly' do
      offer = Offer.new(price: 15.euros)
      offer.save!

      assert_equal offer.price, Offer.where(price: 15.euros).first.price
      assert_equal offer.price, Offer.where(price_amount: 15.00, price_currency: 'EUR').first.price
      assert_empty Offer.where(price: 15.dollars)
    end

    test 'aggregated money attribute reads from mapped amount and currency columns' do
      offer = Offer.new(price_amount: 17.01, price_currency: 'USD')

      assert_equal 17.01.dollars, offer.price
    end

    test 'aggregated money attribute allows nil values' do
      offer = Offer.new(price: nil)

      assert_nil offer.price
      assert_nil offer.price_amount
      assert_nil offer.price_currency
    end

    test 'aggregated money attribute with integer amount column' do
      transaction = FinancialTransaction.new(amount: 45.34.dollars)

      assert_equal 45.34.dollars, transaction.amount
    end

    test 'aggregated money attribute supports custom mappings' do
      mapped_offer = Class.new(ApplicationRecord) do
        self.table_name = 'offers'

        money_attribute :cost, currency: 'USD', mapping: {
          amount: :price_amount,
          currency: :price_currency
        }
      end

      offer = mapped_offer.new(cost: 19.euros)

      assert_equal 19.euros, offer.cost
      assert_equal 19, offer.price_amount
      assert_equal 'EUR', offer.price_currency
    end

    test 'aggregated money attribute requires backing amount and currency columns' do
      invalid_offer = Class.new(ApplicationRecord) do
        self.table_name = 'offers'
      end

      assert_raises(ArgumentError) { invalid_offer.money_attribute :missing_price }
      assert_raises(ArgumentError) do
        invalid_offer.money_attribute :cost, mapping: { price_amount: :amount }
      end
    end

    test 'composite money attribute reads from directly written columns' do
      offer = Offer.new(price_amount: 25, price_currency: 'EUR')

      assert_equal 25.euros, offer.price
    end

    test 'money attribute uses :to_d extractor for decimal columns' do
      assert_equal :to_d, Offer.amount_extractor_for(:price_amount)
    end

    test 'money attribute uses :fractional extractor for integer columns' do
      assert_equal :fractional, FinancialTransaction.amount_extractor_for(:amount)
    end

    test 'composite money attribute accepts zero' do
      offer = Offer.new(price: 0.dollars)

      assert_equal 0.dollars, offer.price
      offer.save!

      assert_equal 0.dollars, offer.reload.price
    end

    test 'composite money attribute accepts negative values' do
      offer = Offer.new(price: -5.50.dollars)

      assert_equal(-5.50.dollars, offer.price)
      offer.save!

      assert_equal(-5.50.dollars, offer.reload.price)
    end

    test 'find_money_attributes error lists missing mapping keys' do
      error = assert_raises(ArgumentError) do
        Class.new(ApplicationRecord) do
          self.table_name = 'offers'

          money_attribute :cost, currency: 'USD', mapping: { amount: :price_amount }
        end
      end
      assert_includes error.message, 'missing required keys'
      assert_includes error.message, 'currency'
    end

    test 'find_money_attributes error lists expected and found columns' do
      invalid_offer = Class.new(ApplicationRecord) do
        self.table_name = 'offers'
      end

      error = assert_raises(ArgumentError) do
        invalid_offer.money_attribute :missing_price, currency: 'USD'
      end
      assert_includes error.message, 'Expected: missing_price_amount, missing_price_currency'
      assert_includes error.message, 'Found:'
    end

    test 'find_money_attributes error with wrong mapping key names' do
      error = assert_raises(ArgumentError) do
        Class.new(ApplicationRecord) do
          self.table_name = 'offers'

          money_attribute :cost, currency: 'USD', mapping: { price_amount: :amount }
        end
      end
      assert_includes error.message, 'missing required keys'
      assert_includes error.message, 'amount, currency'
    end

    test 'parse keeps money values unchanged' do
      parser = MoneyAttribute::Parser.new('USD')

      assert_equal 23.euros, parser.parse('+23.00', 'EUR')
      assert_equal 23.euros, parser.parse(23, 'EUR')
      assert_equal(-25.34.dollars, parser.parse('-25.34'))
      assert_equal(-25.34.dollars, parser.parse('-25.34 EUR'))
      assert_nil MoneyAttribute::Parser.new('USD').parse(nil, 'USD')
      assert_raises(TypeError) { parser.parse(23.euros, 'USD') }
    end

    test 'aggregated money attribute partial custom mapping' do
      assert_raises(ArgumentError) do
        Class.new(ApplicationRecord) do
          self.table_name = 'offers'

          money_attribute :cost, currency: 'USD', mapping: {
            amount: :price_amount
          }
        end
      end
    end
  end
end
