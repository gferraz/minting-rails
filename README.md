# Minting::Rails

Minting::Rails is a gem that provides money attributes to ActiveRecord models. It integrates the [Minting](https://github.com/gferraz/minting) library into your Rails application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'minting-rails'
```

And then execute:

```bash
  bundle
```

## Configuration

After intalling generate Minting configuration initializer:

```sh
rails g mint:initializer
```

You can configure the default currency for your application by adding the following line to your config/initializers/minting.rb:

```ruby
Minting.configure do |config|
  config.default_currency = :usd
end
```

## Usage

To use Minting::Rails, you add the money_attribute method to your ActiveRecord models. For example:

```ruby
class SimpleOffer < ApplicationRecord
  money_attribute :price, currency: 'USD'
  money_attribute :discount, currency: 'USD'
end
```

Now you can use the price attribute as a Money object:

```ruby
product = Product.ne(price: 100)
puts product.price # => "$100.00"
```

## To do

- API Documentation
- Internationalization
- Publish 1.0 Beta

## Contributing

Contribution directions go here.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
