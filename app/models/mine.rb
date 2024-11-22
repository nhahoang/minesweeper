class Mine < ApplicationRecord
  belongs_to :board

  validates :width_position, :height_position, presence: true
end
