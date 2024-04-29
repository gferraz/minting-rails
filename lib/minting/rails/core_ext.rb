class Numeric
  def to_money(currency)
    Mint.money(self, currency)
  end

  def dollars
    Mint.money(self, 'USD')
  end

  def euros
    Mint.money(self, 'EUR')
  end

  alias_method :dollar, :dollars
  alias_method :euro, :euros
  alias_method :mint, :to_money
end

class String
  def to_money(currency)
    Mint.money(to_r, currency)
  end

  alias_method :mint, :to_money
end

