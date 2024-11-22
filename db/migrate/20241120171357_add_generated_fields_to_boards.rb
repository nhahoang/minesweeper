class AddGeneratedFieldsToBoards < ActiveRecord::Migration[8.0]
  def change
    add_column :boards, :generated_mines, :integer, default: 0
  end
end
