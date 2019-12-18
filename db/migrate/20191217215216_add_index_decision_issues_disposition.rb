class AddIndexDecisionIssuesDisposition < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    ActiveRecord::Base.connection.execute "SET statement_timeout = 1800000" # 30 minutes

    add_index :decision_issues, :disposition, algorithm: :concurrently

  ensure
    # always restore the timeout value
    ActiveRecord::Base.connection.execute "SET statement_timeout = 30000" # 30 seconds
  end
end
