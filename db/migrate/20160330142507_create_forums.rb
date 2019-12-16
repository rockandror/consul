class CreateForums < ActiveRecord::Migration[4.2]
  def change
    create_table :forums do |t|
      t.string :name
      t.integer :user_id

      t.timestamps null: false
    end
  end
end