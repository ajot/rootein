class AddPositionToRooteins < ActiveRecord::Migration[8.0]
  def change
    add_column :rooteins, :position, :integer, default: 0
  end
end
