class SetDefaultsHearingWorksheetStatus < ActiveRecord::Migration[5.1]
  def change
    change_column_default :issues, :allow, false
    change_column_default :issues, :deny, false
    change_column_default :issues, :remand, false
    change_column_default :issues, :dismiss, false
  end
end
