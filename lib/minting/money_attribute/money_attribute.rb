# frozen_string_literal: true

module Mint
  # MoneyAttribute
  module MoneyAttribute
    extend ActiveSupport::Concern

    class_methods do
      # Money attribute
      def money_attribute(name, currency: 'GBP', mapping: nil)
        parser = proc { |amount, code = currency| MoneyAttribute.parse(amount, code) }
        if attribute_names.include? name.to_s
          attribute(name, :mint_money, currency:)
          normalizes(name, with: parser)
        else
          aggregated = find_money_attributes(name, mapping:)
          options = {
            allow_nil: true, class_name: 'Mint::Money',
            constructor: parser, converter: parser,
            mapping: { aggregated[:amount] => :to_i, aggregated[:currency] => :currency_code }
          }
          composed_of(name, options)
        end
      end

      def find_money_attributes(name, mapping:)
        composite = if mapping.present?
                      { amount: mapping.key(:amount).to_s, currency: mapping.key(:currency).to_s }
                    else
                      { amount: "#{name}_amount", currency: "#{name}_currency" }
                    end
        if (composite.values & attribute_names).size != 2
          raise ArgumentError, "Could not find attributes to map to #{name} money attribute"
        end

        composite
      end
    end

    def self.parse(amount, currency)
      money = case amount
              when NilClass
                nil
              when Mint::Money
                amount
              when Numeric
                Mint.money(amount, currency)
              else
                if amount.respond_to? :to_money
                  amount.to_money(currency)
                else
                  Mint.money(amount.to_s.split[0].to_r, currency)
                end
              end
      puts "parse(#{amount}, #{currency}) => #{money.inspect}"
      money
    end
  end
end
