class Target < ApplicationRecord
  belongs_to :position

  enum side: %i[buy sell]
  enum category: %i[profit stop]

  MULTIPLIERS = [1.0, 2.0, 3.0]

  before_create :add_side

  def add_side
    self.side = position.long? ? :sell : :buy
  end
end
