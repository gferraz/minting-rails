# Minting::Rails

[![CI](https://github.com/gferraz/minting-rails/actions/workflows/ci.yml/badge.svg)](https://github.com/gferraz/minting-rails/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/minting-rails.svg)](https://badge.fury.io/rb/minting-rails)

Store and read Active Record attributes as `Mint::Money` objects with a single `money_attribute` declaration. No manual serialization, no boilerplate.

```ruby
class Product < ApplicationRecord
  money_attribute :price, currency: 'USD'   # fixed currency, single column
  money_attribute :total                    # multi-currency, two columns
end

Product.new(price: 12).price  # => [USD 12.00]
```

## Quick start

```sh
bundle add minting-rails
bin/rails g mint:initializer
```

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  money_attribute :price, currency: 'USD'
end
```

That's it. `Product.new(price: 12).price` is a `Mint::Money`.

## Why Minting::Rails?

- **No serialization boilerplate** — declare once, read/write `Mint::Money` everywhere.
- **Two storage modes** — single column for fixed-currency apps (simpler), amount+currency columns for multi-currency records (more flexible).
- **Integer or decimal columns** — auto-detects the column type and adjusts serialization (e.g. integer stores cents, decimal stores unit value).
- **Normalizes everything** — pass a number, string, or `Mint::Money`; always get a `Mint::Money` back.
- **Currency enforcement** — fixed-currency attributes reject wrong currencies at assignment time.
- **Built on Rails primitives** — uses `ActiveRecord::Type`, `composed_of`, and `normalizes` under the hood. No monkey-patching of core classes.

### At a glance — vs money-rails

| Feature | minting-rails | money-rails |
|---|---|---|
| **Declaration** | `money_attribute :price` | `monetize :price_cents` |
| **Column types** | `integer`, `decimal`, `bigint` — auto-detected | `integer` cents only |
| **Storage modes** | Single column, composite (amount+currency)| Single cents column, composite (cents+currency) |
| **Decimal columns** | Native — `t.decimal :price` | Not supported — must convert to cents manually |
| **Multi-currency** | `money_attribute :price` (convention: `<name>_amount` + `<name>_currency`) | `monetize :price_cents, with_currency: :price_currency` |
| **Rails integration** | `ActiveRecord::Type` + `composed_of` — no monkey-patches | `monetize` overrides reader/writer methods |
| **Query (fixed)** | `Model.where(price: money)` — `=`, `IN`, `BETWEEN`, `ORDER`, `SUM` | Through cents column (`price_cents`) |
| **Query (multi)** | `Model.where(price: money)` | `Model.where(price_cents:, price_currency:)` |
| **Internal amount** | `Rational`  | `BigDecimal` |
| **Performance** | See [BENCHMARKS.md](BENCHMARKS.md) — wins 9/11 cells |  |

## Requirements

- Ruby 3.3+
- Rails 7.1.3.2+
- [Minting](https://github.com/gferraz/minting) 1.6.0+

## Installation

```ruby
# Gemfile
gem 'minting-rails'
```

```sh
bundle install
bin/rails g mint:initializer
```

The generator creates `config/initializers/minting.rb`.

## Custom currencies

Register non-ISO currencies in `config/initializers/minting.rb`:

```ruby
Currency.register(code: 'CRC', subunit: 2, symbol: '₡')
Currency.register(code: 'NGN', subunit: 3, symbol: '₦')
```

See the [Minting gem](https://github.com/gferraz/minting) for full details on custom currencies, formatting, and rounding.

### I18n / Locale-aware formatting

Minting-rails integrates with Rails I18n to automatically format money amounts according to the current locale.

With `I18n.locale` set to `:en`:
```ruby
Mint.money(1234.56, 'USD').to_s  # => "$1,234.56"
```

Switch to `:'pt-BR'` and the separators change automatically (requires [`rails-i18n`](https://github.com/svenfuchs/rails-i18n) or your own locale file):
```ruby
I18n.locale = :'pt-BR'
Mint.money(1234.56, 'USD').to_s  # => "$1.234,56"
```

The locale backend reads `number.currency.format` from your I18n translations and maps Rails format syntax (`%n` for amount, `%u` for unit) to `Mint::Money#to_s`. If the translation key is missing (no locale file for that language), it falls back to hardcoded defaults (`.` decimal, `,` thousand, `%<symbol>s%<amount>f` format).

You can configure per-sign formatting by adding `positive`, `negative`, and `zero` keys to your locale:

```yaml
# config/locales/minting-rails.en.yml
en:
  number:
    currency:
      format:
        format: "%u%n"           # fallback when no per-sign key matches
        positive: "%u%n"         # "$1,234.56"
        negative: "(%u%n)"       # "($1,234.56)"
        zero: "--"               # "--"
        separator: "."
        delimiter: ","
```

When any of `positive`, `negative`, or `zero` is present, a Hash format is built. Missing keys fall back to `format`:

```ruby
Mint.money(1234.56, 'USD').to_s  # => "$1,234.56"
Mint.money(-1234.56, 'USD').to_s # => "($1,234.56)"
Mint.money(0, 'USD').to_s        # => "--"
```

If none of those keys are set, `format` is used as a plain string (simple formatting).

> Formatting respects the currency's own `subunit` for decimal precision — `I18n` locale settings for `precision` are ignored since that is a currency property, not a locale one.

## Usage — Two modes

### Decision table

| | Fixed currency (single column) | Multi-currency (amount + currency) |
|---|---|---|
| **Migration** | `t.decimal :price` | `t.decimal :price_amount` + `t.string :price_currency` |
| **Model** | `money_attribute :price, currency: 'USD'` | `money_attribute :price` |
| **When to use** | Column always holds the same currency | Each row can hold a different currency |
| **Column type** | `decimal`, `integer`, or `bigint` | `decimal`, `integer`, or `bigint` for amount; `string` for currency |
| **Query** | `Product.where(price: 10.mint('USD'))` — full type support | `Offer.where(price: 10.mint('EUR'))` — equality only |

### Fixed currency (single column)

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
product.price    # => [USD 12.00]
product.discount # => [USD 3.50]
```

A currency mismatch raises `ArgumentError`:

```ruby
Product.new(price: 12.to_money('EUR'))
# => ArgumentError: ... has different currency. Only USD allowed.
```

### Multi-currency (amount + currency columns)

Migration:

```ruby
class CreateOffers < ActiveRecord::Migration[7.1]
  def change
    create_table :offers do |t|
      t.decimal :price_amount
      t.string  :price_currency
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
offer.price          # => [EUR 15.00]
offer.price_amount   # => 15.0
offer.price_currency # => "EUR"
```

The currency is determined by the `money_attribute` declaration:

```ruby
class Offer < ApplicationRecord
  money_attribute :price, currency: 'USD'
end

offer = Offer.new(price: '12')
offer.price.currency.code # => "USD"
```

## Column type detection

Declare the column as `decimal`, `integer`, or `bigint` — the gem adapts:

```ruby
# Migration
create_table :orders do |t|
  t.bigint  :total_amount  # stored as cents (subunits)
  t.string  :total_currency
end

# Model
class Order < ApplicationRecord
  money_attribute :total
end

Order.new(total: 19.99.to_money('USD')).total_amount # => 1999
```

Same for fixed-currency attributes:

```ruby
# Migration
t.bigint :price

# Model (no change needed)
money_attribute :price, currency: 'USD'
```

> Use `integer`/`bigint` for large tables (faster, smaller). Use `decimal` when SQL-level readability matters.

## Custom column names

If your columns don't follow the `<name>_amount` / `<name>_currency` convention:

```ruby
class Invoice < ApplicationRecord
  money_attribute :total, mapping: {
    amount:   :total_amount,
    currency: :currency_code
  }
end
```

The mapping keys are `:amount` and `:currency`; values are your database column names.

## Querying

Fixed-currency attributes support Rails-native querying through the custom type:

```ruby
# Equality
Product.where(price: 10.mint('USD'))

# IN clause
Product.where(price: [10.mint('USD'), 20.mint('USD')])

# BETWEEN
Product.where(price: 10.mint('USD')..20.mint('USD'))

# Ordering
Product.order(price: :desc)

# Aggregation
Product.where(price: 10.mint('USD')).sum(:price)
```

Multi-currency attributes support equality queries via `composed_of`:

```ruby
Offer.where(price: 10.mint('EUR'))
```

For comparisons on multi-currency attributes, use the backing columns directly:

```ruby
Offer.where(price_amount: 10..20, price_currency: 'EUR')
Offer.where('price_amount > ? AND price_currency = ?', 10, 'EUR')
```

## Convenience methods

Minting::Rails adds small helpers on `Numeric` and `String`:

```ruby
12.to_money('USD')    # => [USD 12.00]
12.dollars            # => [USD 12.00]
12.euros              # => [EUR 12.00]
'12.50'.mint('BRL')   # => [BRL 12.50]
```

> If you prefer not to extend core classes, use `Mint::Money.money(12, 'USD')` instead.

## vs money-rails

[Money-rails](https://github.com/RubyMoney/money-rails) is the most popular money-in-Rails gem. Here's how they compare side-by-side.

### Model declaration

```ruby
# minting-rails
class Product < ApplicationRecord
  money_attribute :price, currency: 'USD'          # single column, fixed currency
  money_attribute :total                           # two columns, multi-currency
end

# money-rails
class Product < ApplicationRecord
  monetize :price_cents                            # single cents column, fixed currency
  monetize :total_cents, with_currency: :total_currency  # two columns, multi-currency
end
```

### Migration

```ruby
# minting-rails — any numeric column type
create_table :products do |t|
  t.decimal :price              # stores 12.34
  t.integer :discount           # stores 1234 (cents)
  t.bigint  :total_amount       # stores 1999 (cents)
  t.string  :total_currency
end

# money-rails — integer cents only
create_table :products do |t|
  t.integer :price_cents        # stores 1234 (cents)
  t.integer :discount_cents     # stores 350 (cents)
  t.integer :total_cents
  t.string  :total_currency
end
```

### Reading & writing

```ruby
# minting-rails — pass any type, always get Mint::Money
product.price = 12.34          # stores 12.34 in decimal column
product.price = 1234           # stores 1234 in integer column
product.price = '$12.34'       # parses string
product.price                  # => [USD 12.34]

# money-rails — pass any type, always get Money
product.price_cents = 1234     # stores 1234
product.price = Money.new(1234, 'USD')
product.price                  # => #<Money fractional:1234 currency:USD>
```

### Querying

```ruby
# minting-rails (fixed-currency) — full type-aware querying
Product.where(price: 10.mint('USD'))
Product.where(price: [5.mint('USD'), 10.mint('USD')])
Product.where(price: 5.mint('USD')..15.mint('USD'))
Product.order(price: :desc)
Product.where(price: 10.mint('USD')).sum(:price)

# money-rails — query through cents column
Product.where(price_cents: 1000)
Product.where(price_cents: [500, 1000])
Product.where(price_cents: 500..1500)
Product.order(:price_cents)
```

### Decimal columns

```ruby
# minting-rails — works with decimal columns out of the box
# migration: t.decimal :price
money_attribute :price, currency: 'USD'

product.price = 12.34
product.price           # => [USD 12.34]
product.read_attribute(:price)  # => [USD 12.34]

# money-rails — no decimal column support
# migration: t.decimal :price  ← not supported
# Must use integer cents:
# migration: t.integer :price_cents
monetize :price_cents
product.price_cents = 1234
product.price           # => #<Money fractional:1234 currency:USD>
```

### Multi-currency

```ruby
# minting-rails
money_attribute :price   # expects price_amount + price_currency columns

offer = Offer.new(price: 15.to_money('EUR'))
offer.price             # => [EUR 15.00]
offer.price_amount      # => 15.0
offer.price_currency    # => "EUR"

# money-rails
monetize :price_cents, with_currency: :price_currency

offer = Offer.new(price: Money.new(1500, 'EUR'))
offer.price             # => #<Money fractional:1500 currency:EUR>
offer.price_cents       # => 1500
offer.price_currency    # => "EUR"
```

### Column type auto-detection

```ruby
# minting-rails — same declaration works with any column type
money_attribute :price, currency: 'USD'

# t.decimal :price   → stores human-readable value (12.34)
# t.integer :price   → stores cents (1234)
# t.bigint  :price   → stores cents (1234)

# money-rails — must always match the column name
monetize :price_cents   # column must be price_cents
monetize :price         # column must be price — no support for other types
```

### Performance

See [BENCHMARKS.md](BENCHMARKS.md) for detailed results across instantiation, persistence, reads, queries, arithmetic, and mass inserts. Minting-rails wins 9 of 11 benchmark cells, with the largest advantages in reads (up to 14× faster), arithmetic (6.6×), and mass inserts (1.6×).

### What money-rails has (and minting-rails doesn't)

Minting-rails is intentionally minimal — it focuses on storing and reading money attributes with Rails primitives. Money-rails is a more mature gem (12+ years, 1.9k stars) with a broader feature set that minting-rails does not currently provide:

| Feature | money-rails | minting-rails |
|---|---|---|
| **Mongoid support** | Yes | ActiveRecord only |
| **Migration helpers** | `add_monetize :products, :price` | None |
| **View helpers** | `humanized_money`, `money_without_cents`, etc. | None |
| **I18n / locale files** | Locale-aware formatting via I18n `number.currency.format` — reads your existing translations, no extra setup | Built-in locale-aware formatting with bundled translations |
| **Test matcher** | `monetize(:price_cents)` RSpec matcher | None |
| **Currency exchange** | `default_bank`, `add_rate`, EuCentralBank | None |
| **Custom currencies** | `register_currency` for non-ISO codes | Via `Currency.register` in initializer |
| **Validation integration** | `validates_numericality_of` auto-added | Must add manually |
| **Rounding mode** | Configurable `rounding_mode` | Via `Mint.with_rounding` block |
| **Per-request currency** | Lambda-based for multi-tenant apps | Static per attribute only |
| **Allow nil** | `monetize :x, allow_nil: true` | Must handle nil manually |
| **Parse error control** | `raise_error_on_money_parsing` option | Always raises |
| **Community** | 1.9k stars, 386 forks, 897 commits | New gem |

If you need any of these features today, money-rails may be a better fit. minting-rails fills a specific niche: a lightweight, performant money-in-Rails solution built on standard Rails primitives.

## Roadmap

1. **Method-level currency** — lambda-based currency resolution for multi-tenant and instance-level scenarios
1. **Migration helper**

Contributions and suggestions are welcome — open an issue or PR at [gferraz/minting-rails](https://github.com/gferraz/minting-rails).

## Development

```sh
bundle install
bundle exec rake test
```

The dummy Rails app under `test/dummy` exercises the engine in a full Rails environment.

## Contributing

Bug reports and pull requests welcome at [gferraz/minting-rails](https://github.com/gferraz/minting-rails).

## License

[MIT](MIT-LICENSE)
