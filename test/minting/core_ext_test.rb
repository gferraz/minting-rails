require "test_helper"

class Mint::CoreExtTest < ActiveSupport::TestCase
  test "it adds to_money and mint to Numeric" do
    assert_equal Mint.money(12, :USD), 12.to_money(:USD)
    assert_equal Mint.money(15, :BRL), 15.00.mint(:BRL)
  end

  test "it adds dollars, euros and reais to Numeric" do
    assert_equal Mint.money(12, :USD), 12.dollars
    assert_equal Mint.money(15, :EUR), 15.euros
    assert_equal Mint.money(1, :USD), 1.dollar
    assert_equal Mint.money(1, :EUR), 1.euro
  end

  test "it adds to_money and mint to String" do
    assert_equal Mint.money(12, :USD), '12.00'.to_money(:USD)
    assert_equal Mint.money(13, :BRL), '13.00'.mint(:BRL)
  end
end