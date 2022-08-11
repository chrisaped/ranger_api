class Target < ApplicationRecord
  belongs_to :position

  MULTIPLIERS = [1.0, 2.0, 3.0]
end
