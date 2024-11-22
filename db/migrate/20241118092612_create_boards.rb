class CreateBoards < ActiveRecord::Migration[8.0]
  def change
    create_table :boards do |t|
      t.references :user
      t.string :name
      t.integer :width
      t.integer :height
      t.integer :number_of_mine
      t.timestamps
    end
  end
end
