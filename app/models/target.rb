class Target < ApplicationRecord
  belongs_to :position

  enum side: %i[buy sell]

  MULTIPLIERS = [1.0, 2.0, 3.0]

  before_create :add_side

  def add_side
    if position.long?
      self.side = :sell
    else
      self.side = :buy
    end
  end
end
