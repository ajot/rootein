class AddFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :time_zone, :string, default: "Eastern Time (US & Canada)"
    add_column :users, :notification_email, :boolean, default: true, null: false
  end
end
