class BoardsController < ApplicationController
  before_action :set_board, only: [:show]

  def index
    @boards = Board.includes(:user).page(params[:page]).per(2)
  end

  def top
    @boards = Board.includes(:user).order(id: :desc).limit(10)
  end

  def new
    @board = Board.new
  end

  def show
    @board_grid = Array.new(@board.height) { Array.new(@board.width, '-') }

    @board.mines.each do |mine|
      @board_grid[mine.height_position][mine.width_position] = 'M'
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
