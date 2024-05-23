module Mint
  class Railtie < ::Rails::Railtie
    generators do
      require 'generators/minting/initializer_generator'
    end
  end
end
