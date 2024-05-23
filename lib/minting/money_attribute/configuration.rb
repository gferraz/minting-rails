require 'set'

module Mint

  include ActiveSupport::Configurable

  def self.assert_valid_currency!(currency)
    if currency.is_a? Mint::Currency
      code = currency.code
    else
      code = currency.to_s
      currency = Mint.currency(code)
    end
    return currency if valid_currency_codes.include?(code)
    raise ArgumentError, "Invalid currency '#{code}'. Please select a registered currency: #{valid_currency_codes}"
  end

  def self.default_currency
    @default_currency ||= Mint.assert_valid_currency!(config.default_currency)
  end

  def self.valid_currency_codes

    @valid_currency_codes ||= begin
      if config.enabled_currencies == :all
        Mint.currencies
      else
        config.enabled_currencies.to_set
      end
    end
  end
end