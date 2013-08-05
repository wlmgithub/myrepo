

class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end

  def ceil_to(x)
    (self * 10**x).ceil.to_f / 10**x
  end

  def floor_to(x)
    (self * 10**x).floor.to_f / 10**x
  end
end


class Payment
  def initialize( amount )
    @amount = amount 
  end

  def fee_amount()
     (2.9 * 0.01 * @amount + 0.15).round_to(2)
  end

 
end
