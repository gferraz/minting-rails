# Minting::Rails

Minting::Rails brings [Minting](https://github.com/gferraz/minting) money objects to Active Record models.

It adds a `money_attribute` model helper, registers a `:mint_money` Active Record type, and includes small convenience methods such as `12.to_money('USD')`, `12.dollars`, and `'12.00'.mint('BRL')`.

## What it does

- Stores and reads model attributes as `Mint::Money` objects.
- Supports composed money attributes backed by amount and currency columns.
- Normalizes numeric, string, and `Mint::Money` assignments.
- Validates currencies against the currencies enabled in Minting.

## Requirements

- Ruby 3.3 or newer.
- Rails 7.1.3.2 or newer.
- Minting 1.6.0 or newer.

## Installation

Add the gem to your Rails application's `Gemfile`:

```ruby
gem 'minting-rails'
```

Install it:

```sh
bundle install
```

Generate the initializer:

```sh
bin/rails g mint:initializer
```

## Configuration

Configure Minting in `config/initializers/minting.rb`:

```ruby
Mint.configure do |config|
  config.enabled_currencies = :all
  config.default_currency = 'USD'
  config.default_format = '%<symbol>s%<amount>f'
end
```

You can limit the currencies that may be used:

```ruby
Mint.configure do |config|
  config.enabled_currencies = %w[USD EUR BRL]
  config.default_currency = 'USD'
end
```

You can also register custom currencies before enabling or using them:

```ruby
Mint.configure do |config|
  config.added_currencies = [
    { currency: 'CRC', subunit: 2, symbol: 'CRC' },
    { currency: 'NGN', subunit: 2, symbol: 'NGN' } # subunit is the number of digits after the decimal; USD has 2, JPY has 0, BHD has 3
  ]

  config.enabled_currencies = :all
  config.default_currency = 'CRC'
end
```

The default currency must be registered and included in `enabled_currencies`.

## Usage

Declare money attributes in your Active Record models with `money_attribute`.

### Single-column fixed currency

Use this when a column always stores one currency, such as a `price` column that is always USD.

Migration:

```ruby
class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.decimal :price
      t.decimal :discount

      t.timestamps
    end
  end
end
```

Model:

```ruby
class Product < ApplicationRecord
  money_attribute :price, currency: 'USD'
  money_attribute :discount, currency: 'USD'
end
```

Assignments are normalized to `Mint::Money`:

```ruby
product = Product.new(price: 12, discount: '3.50')

product.price
# => #<Mint::Money ... USD 12.00>

product.discount
# => #<Mint::Money ... USD 3.50>
```

Assigning a `Mint::Money` with a different currency raises `ArgumentError`:

```ruby
Product.new(price: 12.to_money('EUR'))
# raises ArgumentError because the attribute only accepts USD
```

### Amount and currency columns

Use this when each row can store a different currency per record.

Migration:

```ruby
class CreateOffers < ActiveRecord::Migration[7.1]
  def change
    create_table :offers do |t|
      t.decimal :price_amount
      t.string :price_currency

      t.timestamps
    end
  end
end
```

Model:

```ruby
class Offer < ApplicationRecord
  money_attribute :price
end
```

The attribute is composed from `price_amount` and `price_currency`:

```ruby
offer = Offer.new(price: 15.to_money('EUR'))

offer.price
# => #<Mint::Money ... EUR 15.00>

offer.price_amount
# => 15.0

offer.price_currency
# => "EUR"
```

### Integer storage

By default, money attributes are stored as `decimal` columns. If you prefer to store amounts as integer subunits (cents, pence, etc.), use a `bigint` or `integer` column instead. Minting::Rails detects the column type automatically and adapts serialization accordingly.

Migration:

```ruby
class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.bigint  :total_amount
      t.string  :total_currency

      t.timestamps
    end
  end
end
```

Model:

```ruby
class Order < ApplicationRecord
  money_attribute :total
end
```

The amount is stored and retrieved in subunits:

```ruby
order = Order.new(total: 19.99.to_money(:USD))

order.total
# => #<Mint::Money ... USD 19.99>

order.total_amount
# => 1999

order.total_currency
# => "USD"
```

The same applies to single-column fixed-currency attributes:

```ruby
class Ticket < ApplicationRecord
  money_attribute :price, currency: 'USD'
end
```

Migration:

```ruby
t.bigint :price
```

No model change is needed. The column type drives the behavior.

> **Note:** Integer storage is more efficient for large tables. Use Decimal when you need to stay close to SQL standards for interoperability with other systems

### Default Currency

When you assign a plain number or string, Minting::Rails uses `Mint.default_currency`:

```ruby
offer = Offer.new(price: '12')

offer.price.currency_code
# => "USD"
```

### Custom column names

If your amount and currency columns do not follow the `<name>_amount` and `<name>_currency` convention, pass a mapping:

```ruby
class Invoice < ApplicationRecord
  money_attribute :total, mapping: {
    amount: :total_amount,
    currency: :currency_code
  }
end
```

The mapping keys are `:amount` and `:currency`. The values are your database columns.

## Querying

Fixed-currency attributes can be queried with `Mint::Money` values:

```ruby
Product.where(price: 15.to_money('USD'))
```

Composed attributes can also be queried with a money object:

```ruby
Offer.where(price: 15.to_money('EUR'))
```

You can still query the backing columns directly when that is clearer:

```ruby
Offer.where(price_amount: 15, price_currency: 'EUR')
```

## Convenience methods

Minting::Rails adds a few small helpers:

```ruby
12.to_money('USD')
12.mint('BRL')
12.dollars
1.dollar
1.euro
12.euros
'12.50'.to_money('USD')
'12.50'.mint('BRL')
```

These return `Mint::Money` instances.

## Development

Clone the repository and install dependencies:

```sh
bundle install
```

Run the test suite:

```sh
bundle exec rake test
```

The repository includes a dummy Rails application under `test/dummy` for exercising the engine in a Rails environment.

## Contributing

Bug reports and pull requests are welcome on GitHub at [gferraz/minting-rails](https://github.com/gferraz/minting-rails).

Before opening a pull request, please run:

```sh
bundle exec rake test
```

## License

The gem is available as open source under the terms of the [MIT License](MIT-LICENSE).
