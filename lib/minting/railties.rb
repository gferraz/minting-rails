module Mint
  class Railtie < ::Rails::Railtie
    initializer 'mint.initialize', after: 'active_record.initialize_database' do
      Mint::Hooks.init
    end
  end
end