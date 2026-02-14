class AddFieldsToRooteins < ActiveRecord::Migration[8.0]
  def change
    add_column :rooteins, :active, :boolean, default: true, null: false
    add_column :rooteins, :reminder_time, :time
    add_column :rooteins, :remind_on_slack, :boolean, default: false, null: false
  end
end
