class CreateCompletions < ActiveRecord::Migration[8.0]
  def change
    create_table :completions do |t|
      t.references :rootein, null: false, foreign_key: true
      t.date :completed_on

      t.timestamps
    end
    add_index :completions, [:rootein_id, :completed_on], unique: true
  end
end
