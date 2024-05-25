# frozen_string_literal: true

module Mint
  class Railtie < ::Rails::Railtie
    generators do
      require 'generators/minting/initializer_generator'
    end

    config.to_prepare do
      Mint.config.added_currencies do |currency_data|
        Mint.register_currency(*currency_data)
      end
    end
  end
end
