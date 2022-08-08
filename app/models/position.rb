class Position < ApplicationRecord
  enum status: %i[open closed], _default: :open
  enum side: %i[long short]
end
