class AddDescriptionToDocument < ActiveRecord::Migration[5.1]
  def change
    add_column :documents, :description, :string
  end
end
