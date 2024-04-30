# frozen_string_literal: true

require 'test_helper'

module Mint
  class MoneyAttributeTest < ActiveSupport::TestCase
    test 'Money attribute is enabled' do
      assert Offer.attribute :price
    end

    test 'agregated money attribute updates mapped attributes' do
      offer = Offer.new(price: 12.dollars)

      assert_equal 12.dollars, offer.price
      assert_equal 12, offer.price_amount
      assert_equal 'USD', offer.price_currency
    end

    test 'agregated money attribute parses any amount to the default currency' do
      offer = Offer.new(price: '12')

      assert_equal 12.to_money('GBP'), offer.price
      assert_equal 12, offer.price_amount
      assert_equal 'GBP', offer.price_currency
    end

    test 'agregated money attribute are saved correctly' do
      offer = Offer.new(price: 15.euros)
      offer.save!

      found = Offer.where(price: 15.euros).first

      assert_equal offer.price, found.price

      found = Offer.where(price_amount: 15.00, price_currency: 'EUR').first

      assert_equal offer.price, found.price

      found = Offer.where(price: 15.dollars)

      assert_empty found
    end

    test 'agregated money attribute' do
      offer = Offer.new(price_amount: 17.01, price_currency: :EUR)

      assert_equal 17.01.euros, offer.price
    end
  end
end
