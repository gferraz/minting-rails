# frozen_string_literal: true

module Mint
  # MoneyAttribute
  module MoneyAttribute
    extend ActiveSupport::Concern

    class_methods do
      # Money attribute
      def money_attribute(name, currency:, mapping: nil)
        currency = Currency.resolve!(currency)
        parser = Parser.new(currency)
        if attribute_names.include? name.to_s
          attribute(name, :mint_money, currency:)
          normalizes(name, with: parser)
        else
          aggregated = find_money_attributes(name, mapping:)
          options = {
            allow_nil: true, class_name: 'Mint::Money',
            constructor: parser, converter: parser,
            mapping: {
              aggregated[:amount] => amount_extractor_for(aggregated[:amount]),
              aggregated[:currency] => :currency_code
            }
          }
          composed_of(name, options)
        end
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
