require "test_helper"

class Minting::RailsTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert Minting::Rails::VERSION
    assert Minting::VERSION
  end
end
