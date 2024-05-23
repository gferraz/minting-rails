# encoding : utf-8

Mint.configure do |config|
  # Register additional currencies
  #
  # Example:
  #   config.added_currencies = [
  #   Mint.register_currency 'CRC', subunit: 2, symbol: '₡'
  #   Mint.register_currency 'NGN', subunit: 3, synbol: '₦'
  # ]
  config.added_currencies = [
    Mint.register_currency('CRC', subunit: 2, symbol: '₡'),
    Mint.register_currency('NGN', subunit: 3, symbol: '₦')
  ]

  # Enable currencies
  # Only these currencies amounts can be created
  # Examples:
  # 1. All registered currencies are enabled (default)
  #    config.enabled_currencies = :all
  # 2. Some registered currencies are enabled
  #    config.enabled_currencies = %w[BRL CRC NGN USD]

  # To set the default currency
  #
  # It must be a registered currency
  # config.default_currency = 'USD'

  # Specify a rounding mode
  # Any one of:
  #
  # BigDecimal::ROUND_UP,
  # BigDecimal::ROUND_DOWN,
  # BigDecimal::ROUND_HALF_UP,
  # BigDecimal::ROUND_HALF_DOWN,
  # BigDecimal::ROUND_HALF_EVEN,
  # BigDecimal::ROUND_CEILING,
  # BigDecimal::ROUND_FLOOR
  #
  # BigDecimal::ROUND_HALF_EVEN is default
  #
  # config.rounding_mode = BigDecimal::ROUND_HALF_UP
end
