class Position < ApplicationRecord
  has_many :orders

  enum status: %i[open closed], _default: :open
  enum side: %i[long short]
end
