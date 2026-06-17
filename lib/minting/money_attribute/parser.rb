# frozen_string_literal: true

module Mint
  # MoneyAttribute
  module MoneyAttribute
    class Parser
      def initialize(currency)
        @default_currency = Currency.resolve!(currency)
      end

      def parse(amount, currency = nil)
        currency = Currency.resolve!(currency || @default_currency)
        case amount
        when NilClass    then nil
        when Numeric     then Mint::Money.from(amount, currency)
        when String      then Mint::Money.from(amount.to_r, currency)
        when Mint::Money
          return amount if amount.currency == currency

          raise TypeError, "Cannot automatically convert #{amount} to #{currency.code}"
        else
          Mint.parse(amount, currency)
        end
      end
      alias call parse
    end
  end
end
