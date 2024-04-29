
module Mint
  class MintMoneyType < ActiveRecord::Type::Value
    def initialize(currency:)
      @currency = Mint.currency currency
      super()
    end

    def assert_valid_value(value)
      case value
      when Numeric, String
        return
      when Mint::Money
        return if value.currency == @currency

        message = "'#{value.inspect}' has different currency. Only #{@currency.code} allowed."
      else
        message = "'#{value}' is not a valid type for the attribute."
      end
      raise ArgumentError, message
    end

    def deserialize(value)
      puts "deserialize #{value.inspect}"
      value && Mint.money(value, @currency)
    end

    def serialize(value)
      value.to_d
    end

    def self.type
      :mint_type
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Type.register(:mint_money, Mint::MintMoneyType)
end
