class CreateMines < ActiveRecord::Migration[8.0]
  def change
    create_table :mines do |t|
      t.references :board
      t.integer :width_position
      t.integer :height_position
      t.timestamps
    end
  end
end
