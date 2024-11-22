class BoardsController < ApplicationController
  VISIBLE_SIZE = 50
  before_action :set_board, only: [ :show ]

  def index
    @boards = Board.includes(:user).page(params[:page]).per(10)
  end

  def new
    load_home_data
  end

  def show
    @last_width = params[:last_width].to_i || 0
    @last_height = params[:last_height].to_i || 0

    # Set visible area size
    @visible_width = [ VISIBLE_SIZE, @board.width - @last_width ].min
    @visible_height = [ VISIBLE_SIZE, @board.height - @last_height ].min

    # Calculate visible area bounds
    @start_width = @last_width
    @end_width = @last_width + @visible_width
    @start_height = @last_height
    @end_height = @last_height + @visible_height

    @board.generate_mines_for_area(@start_width, @start_height, @visible_width, @visible_height)

    # Initialize grid and populate with mines
    @board_grid = Array.new(@visible_height) { Array.new(@visible_width, 0) }
    visible_mines = @board.mines.where(
      width_position: @start_width...@end_width,
      height_position: @start_height...@end_height
    )

    visible_mines.each do |mine|
      row = mine.height_position - @start_height
      col = mine.width_position - @start_width
      @board_grid[row][col] = 1
    end
  end

  def create
    user = User.find_or_initialize_by(email: board_params[:user])

    if user.new_record? && !user.save
      flash[:alert] = "Invalid email: #{user.errors.full_messages.to_sentence}"
      load_home_data
      render :new, status: :unprocessable_entity
      return
    end

    @board = Board.new(board_params.except(:user).merge(user_id: user.id))

    if @board.save
      redirect_to @board, notice: "Board and mines were successfully created."
    else
      load_home_data
      render :new, status: :unprocessable_entity
    end
  end

  private

  def board_params
    params.require(:board).permit(:user, :name, :width, :height, :number_of_mine)
  end

  def set_board
    @board = Board.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end

  def load_home_data
    last_board = Board.last
    @board = last_board.nil? ? Board.new : Board.new(name: last_board.name, width: last_board.width,
    height: last_board.height, number_of_mine: last_board.number_of_mine, user: last_board.user)
    @recent_boards = Board.includes(:user).order(id: :desc).limit(10)
  end
end
