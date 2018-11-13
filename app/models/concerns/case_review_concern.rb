module CaseReviewConcern
  extend ActiveSupport::Concern

  attr_accessor :issues

  included do
    validates :task, presence: true, unless: :legacy?
  end

  def appeal
    @appeal ||= if legacy?
                  LegacyAppeal.find_or_create_by(vacols_id: vacols_id)
                else
                  Task.find(task_id).appeal
                end
  end

  def update_task_and_issue_dispositions
    task.update(status: :completed)

    if task.type == "AttorneyTask" && task.assigned_by_id != reviewing_judge_id
      task.parent.update(assigned_to_id: reviewing_judge_id)
    end
    (issues || []).each do |issue_attrs|
      # Delete this check when we turn on the feature flag: ama_decision_issues
      if issue_attrs[:decision_issues]
        update_decision_and_request_issues_disposition
      else
        update_issue_disposition(issue_attrs)
      end
    end
  end

  def update_decision_and_request_issues_disposition(issue_attrs)
    request_issues = appeal.request_issues.where(id: issue_attrs["request_issue_ids"]) if appeal
    # create decision issues and set their dispositions
    # if decision issue id is not passed, create a decision issue
    # if decision issue id is passed, we will update the issue
    # if decision issue already exists and not passed in the request delete it


    # issue_attrs[:decision_issues].each do |decision_issue_attrs|
    #   if decision_issue_attrs[:id]
    #     request_issues.decision_issues.find(decision_issue_attrs[:id])
    # end

    request_issues.update_all((disposition: issue_attrs["request_issue_disposition"]))
  end

  def update_issue_disposition(issue_attrs)
    request_issue = appeal.request_issues.find_by(id: issue_attrs["id"]) if appeal
    return unless request_issue

    request_issue.update(disposition: issue_attrs["disposition"])
    # If disposition was remanded and now is changed to another dispostion,
    # delete all remand reasons associated with the request issue
    update_remand_reasons(request_issue, issue_attrs["remand_reasons"] || [])
  end

  def update_remand_reasons(request_issue, remand_reasons_attrs)
    remand_reasons_attrs.each do |remand_reason_attrs|
      request_issue.remand_reasons.find_or_initialize_by(code: remand_reason_attrs["code"]).tap do |record|
        record.post_aoj = remand_reason_attrs["post_aoj"]
        record.save!
      end
    end
    # Delete remand reasons that are not part of the request
    existing_codes = request_issue.reload.remand_reasons.pluck(:code)
    codes_to_delete = existing_codes - remand_reasons_attrs.pluck("code")
    request_issue.remand_reasons.where(code: codes_to_delete).delete_all
  end

  def update_issue_dispositions_in_vacols!
    (issues || []).each do |issue_attrs|
      Issue.update_in_vacols!(
        vacols_id: vacols_id,
        vacols_sequence_id: issue_attrs[:id],
        issue_attrs: {
          vacols_user_id: modifying_user,
          disposition: issue_attrs[:disposition],
          disposition_date: VacolsHelper.local_date_with_utc_timezone,
          readjudication: issue_attrs[:readjudication],
          remand_reasons: issue_attrs[:remand_reasons]
        }
      )
    end
  end

  def legacy?
    (task_id =~ LegacyTask::TASK_ID_REGEX) ? true : false
  end

  def vacols_id
    task_id.split("-", 2).first if task_id
  end

  def created_in_vacols_date
    task_id.split("-", 2).second.to_date if task_id
  end
end
