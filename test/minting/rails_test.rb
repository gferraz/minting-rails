require "test_helper"

class Mint::RailsTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert Mint::MoneyAttribute::VERSION
    assert Minting::VERSION
  end
end
