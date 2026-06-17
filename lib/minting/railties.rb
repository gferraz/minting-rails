# frozen_string_literal: true

module Mint
  class Railtie < ::Rails::Railtie
    generators do
      require 'generators/minting/initializer_generator'
    end

    config.after_initialize do
      setup_locale_backend!
    end

    def self.setup_locale_backend!
      Mint.locale_backend = lambda {
        fmt = I18n.t('number.currency.format', default: {})
        translator = ->(s) { s&.gsub('%n', '%<amount>f')&.gsub('%u', '%<symbol>s') }

        format = if fmt.key?(:positive) || fmt.key?(:negative) || fmt.key?(:zero)
                   {
                     positive: translator.call(fmt[:positive] || fmt[:format]),
                     negative: translator.call(fmt[:negative] || fmt[:format]),
                     zero: translator.call(fmt[:zero] || fmt[:format])
                   }
                 else
                   translator.call(fmt[:format])
                 end

        { decimal: fmt[:separator], thousand: fmt[:delimiter], format: format }
      }
    end
  end
end
