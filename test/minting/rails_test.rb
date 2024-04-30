# frozen_string_literal: true

require 'test_helper'

module Mint
  class RailsTest < ActiveSupport::TestCase
    test 'it has a version number' do
      assert Mint::MoneyAttribute::VERSION
      assert Minting::VERSION
    end
  end
end
