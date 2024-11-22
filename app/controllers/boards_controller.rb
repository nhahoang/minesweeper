class BoardsController < ApplicationController
  before_action :set_board, only: [:show]

  def index
    @boards = Board.includes(:user).page(params[:page]).per(10)
  end

  def top
    @boards = Board.includes(:user).order(id: :desc).limit(10)
  end

  def new
    @board = Board.new
    @recent_boards = Board.includes(:user).order(id: :desc).limit(10)
  end

  def show
    @last_width = params[:last_width].to_i || 0
    @last_height = params[:last_height].to_i || 0
  
    # Set the visible grid size (5x5)
    @visible_width = @board.width < 20 ? @board.width : 20
    @visible_height = @board.height < 20 ? @board.height : 20
  
    # Calculate grid boundaries
    @start_width = @last_width
    @end_width = [@last_width + @visible_width, @board.width].min
    @start_height = @last_height
    @end_height = [@last_height + @visible_height, @board.height].min
  
    # Initialize the visible grid
    @board_grid = Array.new(@visible_height) { Array.new(@visible_width, '-') }
  
    # Fetch mines only within the visible grid boundaries
    visible_mines = @board.mines.where(
      width_position: @start_width...@end_width,
      height_position: @start_height...@end_height
    )
  
    visible_mines.each do |mine|
      row = mine.height_position - @start_height
      col = mine.width_position - @start_width
      @board_grid[row][col] = 'M'
    end
  end
  

  def create
    user = User.find_or_create_by(email: board_params[:user]) 
    @board = Board.new(board_params.except(:user).merge(user_id: user.id))

    if @board.save
      begin
        @board.generate_mines
        redirect_to @board, notice: 'Board and mines were successfully created.'
      rescue => e
        @board.destroy # Cleanup incomplete board if mines creation fails
        flash[:alert] = "Error creating mines: #{e.message}"
        render :new, status: :unprocessable_entity
      end
    else
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
end
