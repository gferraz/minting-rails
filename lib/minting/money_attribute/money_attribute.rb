module Mint
  module MoneyAttribute
    extend ActiveSupport::Concern

    class_methods do
      # Money attribute
      def money_attribute(name, currency: 'GBP', mapping: nil)
        parser = proc { |amount, code = currency|  parse_money(amount, code) }
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

      private

      def find_money_attributes(name, mapping:)
        {}.tap do |c|
          if mapping.present?
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
        money = case amount
        when NilClass
          nil
        when Mint::Money
          amount
        when Numeric
          Mint.money(amount, currency)
        else
          Mint.money(amount.to_s.split[0].to_r, currency)
        end
        # puts "parse(#{amount}, #{currency}) => #{money.inspect}"
        money
      end
    end
  end
end

ActiveRecord::Base.include Mint::MoneyAttribute
