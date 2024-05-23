module Mint
  module Generators
    class InitializerGenerator < ::Rails::Generators::Base
      source_root File.expand_path('../templates', __dir__)

      desc 'Creates Minting initializer.'

      def copy_initializer
        copy_file 'minting.rb', 'config/initializers/minting.rb'
      end
    end
  end
end
