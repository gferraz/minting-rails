# frozen_string_literal: true

require 'test_helper'

module Mint
  class RailsTest < ActiveSupport::TestCase
    setup do
      @original_locale_backend = Mint.locale_backend
      @original_locale = I18n.locale
    end

    teardown do
      Mint.locale_backend = @original_locale_backend
      I18n.locale = @original_locale
    end

    test 'it has a version number' do
      assert Mint::MoneyAttribute::VERSION
      assert Minting::VERSION
    end

    test 'locale backend is configured and returns defaults' do
      assert_respond_to Mint.locale_backend, :call
      result = Mint.locale_backend.call
      assert_kind_of Hash, result
      assert_includes result.keys, :decimal
      assert_includes result.keys, :thousand
      assert_includes result.keys, :format
    end

    test 'locale backend reads from Rails I18n for current locale' do
      I18n.locale = :en

      result = Mint.locale_backend.call
      assert_equal '.', result[:decimal]
      assert_equal ',', result[:thousand]
      assert_equal '%<symbol>s%<amount>f', result[:format]
    end

    test 'format string is mapped from Rails to minting syntax' do
      Mint.locale_backend = -> {
        { decimal: ',', thousand: '.', format: '%<amount>f %<symbol>s' }
      }
      result = Mint.locale_backend.call
      assert_equal '%<amount>f %<symbol>s', result[:format]

      Mint.locale_backend = -> {
        { decimal: '.', thousand: ',', format: '%<symbol>s%<amount>f' }
      }
      result = Mint.locale_backend.call
      assert_equal '%<symbol>s%<amount>f', result[:format]
    end

    test 'locale backend formats money with locale-aware separators' do
      Mint.locale_backend = -> {
        { decimal: ',', thousand: '.', format: '%<symbol>s %<amount>f' }
      }
      money = Mint.money(1234.56, 'USD')
      assert_equal '$ 1.234,56', money.to_s
    end

    test 'locale backend returns string format when no per-sign keys' do
      Mint.locale_backend = -> {
        { decimal: '.', thousand: ',', format: '%<symbol>s%<amount>f' }
      }
      result = Mint.locale_backend.call
      assert_kind_of String, result[:format]
      assert_equal '%<symbol>s%<amount>f', result[:format]
    end

    test 'locale backend returns hash format when positive key is present' do
      Mint.locale_backend = -> {
        gsub = ->(s) { s&.gsub('%n', '%<amount>f')&.gsub('%u', '%<symbol>s') }
        fmt = { format: '%u%n', positive: '%u%n', separator: '.', delimiter: ',' }
        {
          decimal: fmt[:separator],
          thousand: fmt[:delimiter],
          format: if fmt.key?(:positive) || fmt.key?(:negative) || fmt.key?(:zero)
            {
              positive: gsub.call(fmt[:positive] || fmt[:format]),
              negative: gsub.call(fmt[:negative] || fmt[:format]),
              zero:     gsub.call(fmt[:zero] || fmt[:format])
            }
          else
            gsub.call(fmt[:format])
          end
        }
      }
      result = Mint.locale_backend.call
      assert_kind_of Hash, result[:format]
      assert_includes result[:format], :positive
      assert_includes result[:format], :negative
      assert_includes result[:format], :zero
    end

    test 'locale backend hash format respects negative and zero overrides' do
      Mint.locale_backend = -> {
        gsub = ->(s) { s&.gsub('%n', '%<amount>f')&.gsub('%u', '%<symbol>s') }
        fmt = { format: '%u%n', negative: '(%u%n)', zero: '--', separator: '.', delimiter: ',' }
        {
          decimal: fmt[:separator],
          thousand: fmt[:delimiter],
          format: if fmt.key?(:positive) || fmt.key?(:negative) || fmt.key?(:zero)
            positive = gsub.call(fmt[:positive] || fmt[:format])
            negative = gsub.call(fmt[:negative] || fmt[:format])
            zero = gsub.call(fmt[:zero] || fmt[:format])
            { positive:, negative:, zero: }
          else
            gsub.call(fmt[:format])
          end
        }
      }

      positive = Mint.money(10.00, 'USD')
      negative = Mint.money(-10.00, 'USD')
      zero     = Mint.money(0, 'USD')

      assert_equal '$10.00', positive.to_s
      assert_equal '($10.00)', negative.to_s
      assert_equal '--', zero.to_s
    end

    test 'locale backend hash format falls back to format for missing per-sign keys' do
      Mint.locale_backend = -> {
        gsub = ->(s) { s&.gsub('%n', '%<amount>f')&.gsub('%u', '%<symbol>s') }
        fmt = { format: '[%u%n]', negative: '(%u%n)', separator: '.', delimiter: ',' }
        {
          decimal: fmt[:separator],
          thousand: fmt[:delimiter],
          format: if fmt.key?(:positive) || fmt.key?(:negative) || fmt.key?(:zero)
            {
              positive: gsub.call(fmt[:positive] || fmt[:format]),
              negative: gsub.call(fmt[:negative] || fmt[:format]),
              zero:     gsub.call(fmt[:zero] || fmt[:format])
            }
          else
            gsub.call(fmt[:format])
          end
        }
      }

      assert_equal '[$10.00]',   Mint.money(10.00, 'USD').to_s
      assert_equal '($10.00)',   Mint.money(-10.00, 'USD').to_s
      assert_equal '[$0.00]',    Mint.money(0, 'USD').to_s
    end

  end
end
