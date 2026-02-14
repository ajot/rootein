class CreateRooteins < ActiveRecord::Migration[8.0]
  def change
    create_table :rooteins do |t|
      t.string :name

      t.timestamps
    end
  end
end
