class Board < ApplicationRecord
  has_many :mines, dependent: :destroy
  belongs_to :user

  validates :width, :height, :number_of_mine, presence: true

  def generate_mines
    # Ensure valid mine count
    raise "Too many mines for board size" if number_of_mine > width * height

    # Generate unique random positions
    positions = []
    until positions.size == number_of_mine
      pos = [rand(width), rand(height)]
      positions << pos unless positions.include?(pos)
    end

    # Save mines to the database
    positions.each do |x, y|
      mines.create!(width_position: x, height_position: y)
    end
  end
end
