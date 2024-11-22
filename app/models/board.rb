class Board < ApplicationRecord
  has_many :mines, dependent: :destroy
  belongs_to :user

  validates :name, presence: true, length: { maximum: 255 }
  validates :width, :height, :number_of_mine, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def find_mines_in_area(start_width, end_width, start_height, end_height)
    mines.where(
      width_position: start_width...end_width,
      height_position: start_height...end_height
    )
  end

  def generate_mines_for_area(start_width, start_height, visible_width, visible_height)
    # Find exist mines in visible area
    exist_mines = find_mines_in_area(start_width, start_width + visible_width, start_height, start_height + visible_height)

    # Calculate the actual remaining cells in the visible area
    remaining_cells = visible_width * visible_height

    # Calculate the number of mines to generate for the current area
    mines_to_generate = (number_of_mine * remaining_cells.to_f / (width * height)).ceil

    return if exist_mines.length == mines_to_generate

    exist_positions = exist_mines.each_with_object({}) {
      |em, hash| hash[[ em.width_position, em.height_position ]] = true
    }

    # Generate unique random positions for the mines
    positions = {}
    needed_positions = mines_to_generate - exist_positions.length
    while positions.length < needed_positions
      x = rand(start_width...(start_width + visible_width))
      y = rand(start_height...(start_height + visible_height))
      key = [ x, y ]

      # Avoid duplicate positions by checking only once
      positions[key] ||= true unless exist_positions[key]
    end

    # Prepare data for bulk insertion into the database
    new_mines = positions.keys.map do |(x, y)|
      { board_id: id, width_position: x, height_position: y, created_at: Time.now, updated_at: Time.now }
    end

    # Insert all new mines into the database in a single query
    Mine.insert_all(new_mines)

    # Update the count of generated mines
    update!(generated_mines: generated_mines + new_mines.length)
  end
end
