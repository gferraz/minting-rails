# encoding : utf-8

Mint.configure do |config|



  # Register a custom currency
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
  # Example:
  # config.enabled_currencies = :all

  config.enabled_currencies = %w[BRL CRC NGN USD]


  # To set the default currency
  #
  # It must be a registered currency
  #
  config.default_currency = 'BRL'


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
  # set to BigDecimal::ROUND_HALF_EVEN by default
  #
  # config.rounding_mode = BigDecimal::ROUND_HALF_UP

  # Set default money format globally.
  # Default value is nil meaning "ignore this option".
  # Example:
  #
  # config.default_format = {
  #   no_cents_if_whole: nil,
  #   symbol: nil,
  #   sign_before_symbol: nil
  # }
end