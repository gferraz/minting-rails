require 'test_helper'

class Mint::MoneyAttributeTest < ActiveSupport::TestCase
  test 'Money attribute is enabled' do
    assert Offer.attribute :price
  end
end
