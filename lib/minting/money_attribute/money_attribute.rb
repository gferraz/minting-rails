# frozen_string_literal: true

module Mint
  # MoneyAttribute
  module MoneyAttribute
    extend ActiveSupport::Concern

    class_methods do
      # Money attribute
      def money_attribute(name, currency: 'XXX', mapping: nil, currency_via: nil)
        currency = Currency.resolve(currency)
        parser = Parser.new(currency)

        if currency_via
          code_attr = :"_#{name}_currency_code"
          attribute(code_attr, :string)
          mapping ||= {}
          mapping[:amount] ||= name
          mapping[:currency] ||= code_attr
        end

        if mapping
          aggregated = find_money_attributes(name, mapping:)
        elsif attribute_names.include?(name.to_s)
          attribute(name, :mint_money, currency:)
          normalizes(name, with: parser)
          return
        else
          aggregated = find_money_attributes(name, mapping: nil)
        end

        amount_column = aggregated[:amount]
        currency_column = aggregated[:currency]

        col = columns.find { |c| c.name == amount_column }
        is_integer = col&.type.in?(%i[integer bigint])

        constructor = if is_integer
                        lambda do |amount, currency_code|
                          return nil if amount.nil?

                          Mint::Money.from_fractional(
                            amount,
                            Currency.resolve!(currency_code || currency)
                          )
                        end
                      else
                        parser
                      end

        options = {
          allow_nil: true, class_name: 'Mint::Money',
          constructor:, converter: parser,
          mapping: {
            amount_column => amount_extractor_for(amount_column),
            currency_column => :currency_code
          }
        }
        composed_of(name, options)

        return unless currency_via

        define_method(:"_ma_af_#{name}") do
          code = if currency_via.respond_to?(:call)
                   currency_via.call(self)
                 else
                   send(currency_via)&.code
                 end
          write_attribute(:"_#{name}_currency_code", code)
        end
        after_find :"_ma_af_#{name}"
      end

      def amount_extractor_for(column_name)
        col = columns.find { |c| c.name == column_name.to_s }

        case col&.type
        when :bigint, :integer
          :fractional
        else
          :to_d # :decimal, :numeric, unknown
        end
      end

      def find_money_attributes(name, mapping:)
        if mapping.present?
          missing_keys = (%i[amount currency] - mapping.keys).join(', ')
          if missing_keys.present?
            raise ArgumentError,
                  "Mapping for :#{name} money attribute is missing required keys: #{missing_keys}"
          end
          composite = { amount: mapping[:amount].to_s, currency: mapping[:currency].to_s }
        else
          composite = { amount: "#{name}_amount", currency: "#{name}_currency" }
        end

        missing = composite.values - attribute_names
        if missing.any?
          raise ArgumentError,
                "Could not find columns for :#{name} money attribute. " \
                "Expected: #{composite.values.join(', ')}, " \
                "Found: #{attribute_names.join(', ')}"
        end

        composite
      end
    end
  end
end
