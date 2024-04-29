module Minting
  module MoneyAttribute
    extend ActiveSupport::Concern

    class_methods do
      # Money attribute
      def money_attribute(name, allow_nil: true, currency: 'GBP', composite: nil, mapping: nil)
        if attribute_names.include? name.to_s
          attribute(name, :mint, currency:)
          normalizes(name, with: -> value { Offer.parse_money(value, currency) })
        else
          composite = find_money_attributes(name, mapping:)
          mapping = { composite[:amount] => :to_i, composite[:currency] => :currency_code }
          options = {
            allow_nil:, class_name: 'Mint::Money', mapping:,
            constructor: proc { |amount, currency_code|
              puts "constructor";
              parse_money(amount, currency_code || currency)
            },
            converter: proc { |amount, currency_code|
              puts "convert: #{amount.inspect}, #{currency_code.inspect}"
              parse_money(amount, currency_code || currency)
            }
          }
          composed_of(name, options)
        end
      end

      private

      def find_money_attributes(name, mapping:)
        {}.tap do |c|
          if mapping
            c[:amount] = mapping.key(:amount).to_s
            c[:currency] = mapping.key(:currency).to_s
          else
            c[:amount] = "#{name}_amount"
            c[:currency] = "#{name}_currency"
          end
          if (c.values & attribute_names).size != 2
            raise ArgumentError, "Could not find attributes to map to #{name} money attribute"
          end
        end
      end

      def parse_money(amount, currency)
        puts "parse(#{amount}, #{currency})"
        case amount
        when NilClass
          nil
        when Mint::Money
          amount
        when Numeric
          Mint.money(amount, currency)
        else
          Mint.money(amount.to_s.split[0].to_r, currency)
        end
      end

    end
  end
end

ActiveRecord::Base.include Minting::MoneyAttribute

