class MakeHearingViewsPolymorphic < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    add_column :hearing_views, :hearing_type, :string
    remove_index :hearing_views, [:hearing_id, :user_id]
    add_index :hearing_views, [:hearing_id, :user_id, :hearing_type], unique: true
  end
end
