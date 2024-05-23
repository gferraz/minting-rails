# frozen_string_literal: true

require 'test_helper'

module Mint
  class RailsTest < ActiveSupport::TestCase
    test 'it has a version number' do
      assert Mint::MoneyAttribute::VERSION
      assert Minting::VERSION
    end

    test 'default currency configuration' do
      assert_equal 'BRL', Mint.default_currency.code
    end

    test 'enable currencies configuration' do
      assert_equal %w[BRL CRC NGN USD], Mint.config.enabled_currencies
      assert_equal %w[BRL CRC NGN USD].to_set, Mint.valid_currency_codes

      assert_equal Mint.currency('BRL'), Mint.assert_valid_currency!('BRL')
      assert_equal Mint.currency('USD'), Mint.assert_valid_currency!('USD')
      assert_raises(ArgumentError) {  Mint.assert_valid_currency!('EUR') }
      assert_raises(ArgumentError) {  Mint.assert_valid_currency!('GBP') }
    end
  end
end
