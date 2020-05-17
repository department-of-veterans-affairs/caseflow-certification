class CreateEtlRemandReason < ActiveRecord::Migration[5.2]
  def change
    create_table :remand_reasons, comment: "Copy of remand_reasons" do |t|
      t.timestamps null: false, comment: "Default created_at/updated_at for the ETL record"
      t.index ["created_at"]
      t.index ["updated_at"]

      t.datetime "remand_reason_created_at"
      t.datetime "remand_reason_updated_at"
      t.index ["remand_reason_created_at"]
      t.index ["remand_reason_updated_at"]

      t.string "code", limit: 30
      t.index ["code"]

      t.integer "decision_issue_id"
      t.index ["decision_issue_id"]

      t.boolean "post_aoj"
      t.index ["post_aoj"]
    end
  end
end
