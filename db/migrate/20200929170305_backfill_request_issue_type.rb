class BackfillRequestIssueType < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!


  def change
  	RequestIssue.unscoped.in_batches do |relation|
      relation.update_all request_issue_type: "RequestIssue"
      sleep(0.1)
    end
  end
end
