# frozen_string_literal: true

require 'test_helper'

module Mint
  class SimpleMoneyAttributeTest < ActiveSupport::TestCase
    test 'Money attribute is enabled' do
      assert SimpleOffer.attribute :price
      assert SimpleOffer.attribute :discount
    end

    test 'money attribute updates mapped attributes' do
      offer = SimpleOffer.new(price: 12.mint(:GBP), discount: 15)

      assert_equal 12.mint(:GBP), offer.price
      assert_equal 15.mint(:GBP), offer.discount
    end

    test 'money attribute parses any amount to the default currency' do
      offer = SimpleOffer.new(price: '12')

      assert_equal 12.to_money('GBP'), offer.price
    end

    test 'money attribute are saved correctly' do
      offer = SimpleOffer.new(price: 15.mint(:GBP), discount: 45.01)
      offer.save!

      found = SimpleOffer.where(price: 15.mint(:GBP)).first

      assert_equal offer.price, found.price
      assert_equal offer.discount, found.discount
    end
  end
end
