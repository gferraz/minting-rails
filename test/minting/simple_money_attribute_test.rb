# frozen_string_literal: true

require 'test_helper'

module Mint
  class SimpleMoneyAttributeTest < ActiveSupport::TestCase
    test 'Money attribute is enabled' do
      assert SimpleOffer.attribute :price
      assert SimpleOffer.attribute :discount
    end

    test 'money attribute updates mapped attributes' do
      offer = SimpleOffer.new(price: 12.money('USD'), discount: 15)

      assert_equal 12.money('USD'), offer.price
      assert_equal 15.money('USD'), offer.discount

      assert_raises(ArgumentError) { SimpleOffer.new(price: 12.money('USD'), discount: 15.euros) }
    end

    test 'money attribute parses any amount to the default currency' do
      offer = SimpleOffer.new(price: '12')

      assert_equal 12.to_money('USD'), offer.price
    end

    test 'money attribute allows nil values' do
      offer = SimpleOffer.new(price: nil, discount: nil)

      assert_nil offer.price
      assert_nil offer.discount
    end

    test 'money attribute is saved correctly' do
      offer = SimpleOffer.new(price: 15.money('USD'), discount: 45.01)
      offer.save!

      found = SimpleOffer.where(price: 15.money('USD')).first

      assert_equal offer.price, found.price
      assert_equal offer.discount, found.discount
    end

    test 'money attribute serializes nil values' do
      offer = SimpleOffer.create!(price: nil, discount: nil)

      found = SimpleOffer.find(offer.id)

      assert_nil found.price
      assert_nil found.discount
    end

    test 'single-column money attribute rejects different currency' do
      error = assert_raises(ArgumentError) { SimpleOffer.new(price: 15.euros) }
      assert_match(/different currency/, error.message)
    end

    test 'single-column money attribute normalizes string inputs' do
      offer = SimpleOffer.new(price: '12.50')

      assert_equal 12.50.money('USD'), offer.price
    end

    test 'single-column money attribute accepts zero' do
      offer = SimpleOffer.new(price: 0.money('USD'))

      assert_equal 0.money('USD'), offer.price
      offer.save!

      assert_equal 0.money('USD'), offer.reload.price
    end

    test 'single-column money attribute accepts negative values' do
      offer = SimpleOffer.new(price: -5.50.money('USD'))

      assert_equal(-5.50.money('USD'), offer.price)
      offer.save!

      assert_equal(-5.50.money('USD'), offer.reload.price)
    end
  end
end
