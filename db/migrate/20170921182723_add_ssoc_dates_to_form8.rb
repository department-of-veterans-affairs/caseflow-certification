class AddSsocDatesToForm8 < ActiveRecord::Migration[5.1]
  def change
    add_column :form8s, :ssoc_date_1, :date
    add_column :form8s, :ssoc_date_2, :date
    add_column :form8s, :ssoc_date_3, :date
  end
end
