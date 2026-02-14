class CreateTips < ActiveRecord::Migration[8.0]
  def change
    create_table :tips do |t|
      t.text :body

      t.timestamps
    end
  end
end
