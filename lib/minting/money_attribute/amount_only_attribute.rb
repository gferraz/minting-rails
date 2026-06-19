# frozen_string_literal: true

module Mint
  module AmountOnlyAttribute
    extend ActiveSupport::Concern

    class_methods do
      private

      def amount_only_attribute(name, currency:)
        case currency
        when String
          effective = ->(_r) { currency }
          fallback = currency
        when ->(c) { c.respond_to?(:call) }
          effective = currency
          fallback = 'XXX'
        else
          raise ArgumentError,
                "amount_only_attribute requires a String or callable for currency:, got: #{currency.class}"
        end

        code_attr = :"_#{name}_currency_code"
        attribute(code_attr, :string)

        col = columns.find { |c| c.name == name.to_s }
        is_integer = col&.type.in?(%i[integer bigint])

        constructor = if is_integer
                        lambda do |amount, currency_code|
                          return nil if amount.nil?

                          Mint::Money.from_fractional(amount, Currency.resolve!(currency_code))
                        end
                      else
                        lambda do |amount, currency_code|
                          return nil if amount.nil?

                          Mint::Money.from(amount, Currency.resolve!(currency_code))
                        end
                      end

        converter = lambda do |value|
          case value
          when NilClass then nil
          when Mint::Money then value
          when Numeric then Mint::Money.from(value, Currency.resolve!(fallback))
          when String then Mint::Money.from(value.to_r, Currency.resolve!(fallback))
          else Mint::Money.from(value, Currency.resolve!(fallback))
          end
        end

        options = {
          allow_nil: true, class_name: 'Mint::Money',
          constructor:, converter:,
          mapping: {
            name => amount_extractor_for(name),
            code_attr => :currency_code
          }
        }
        composed_of(name, options)

        define_method(:"_ma2_af_#{name}") do
          write_attribute(code_attr, effective.call(self))
        end
        after_find :"_ma2_af_#{name}"
      end

      def amount_extractor_for(column_name)
        col = columns.find { |c| c.name == column_name.to_s }

        case col&.type
        when :bigint, :integer then :fractional
        else :to_d
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  include Mint::AmountOnlyAttribute
end
