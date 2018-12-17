module IssueUpdater
  extend ActiveSupport::Concern

  def update_issue_dispositions_in_caseflow!
    # Remove this check when feature flag 'ama_decision_issues' is enabled for all. Similarly,
    use_ama_decision_issues? ? update_issue_dispositions! : update_issue_dispositions_deprecated!
  end

  def update_issue_dispositions!
    return unless appeal
    # We will always delete and re-create decision issues on attorney/judge checkout
    delete_decision_issues
    create_decision_issues
    fail_if_not_all_request_issues_have_decision!
  end

  def update_issue_dispositions_in_vacols!
    fail_if_invalid_issues_attrs!

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

  private

  def delete_decision_issues
    decision_issue_ids_to_delete = appeal.decision_issues.map(&:id)
    DecisionIssue.where(id: decision_issue_ids_to_delete).destroy_all
  end

  def create_decision_issues
    issues.each do |issue_attrs|
      request_issues = appeal.request_issues.where(id: issue_attrs[:request_issue_ids])
      next if request_issues.empty?

      decision_issue = DecisionIssue.create!(
        disposition: issue_attrs[:disposition],
        description: issue_attrs[:description],
        benefit_type: issue_attrs[:benefit_type],
        participant_id: appeal.veteran.participant_id,
        decision_review: appeal
      )

      request_issues.each do |request_issue|
        RequestDecisionIssue.create!(decision_issue: decision_issue, request_issue: request_issue)
      end
      create_remand_reasons(decision_issue, issue_attrs[:remand_reasons] || [])
    end
  end

  def fail_if_not_all_request_issues_have_decision!
    unless appeal.every_request_issue_has_decision?
      fail Caseflow::Error::AttorneyJudgeCheckoutError, message: "Not every request issue has a decision issue"
    end
  end

  def fail_if_invalid_issues_attrs!
    return if is_a?(AttorneyCaseReview) && omo_request?

    fail_if_count_mismatch!
    fail_if_no_dispositions!
  end

  def fail_if_no_dispositions!
    if (issues || []).map { |issue| issue[:disposition].present? }.uniq != [true]
      msg = "Issues in the request are missing dispositions"
      fail Caseflow::Error::AttorneyJudgeCheckoutError, message: msg
    end
  end

  def fail_if_count_mismatch!
    if (issues || []).count != (legacy? ? appeal.issues.count : appeal.request_issues.count)
      msg = "Number of issues in the request does not match the number in the database"
      fail Caseflow::Error::AttorneyJudgeCheckoutError, message: msg
    end
  end

  def fail_if_no_remand_reasons!(issue, remand_reasons_attrs)
    if issue.disposition == "remanded" && remand_reasons_attrs.blank?
      msg = "Remand reasons are missing for a remanded issue"
      fail Caseflow::Error::AttorneyJudgeCheckoutError, message: msg
    end
  end

  def use_ama_decision_issues?
    FeatureToggle.enabled?(:ama_decision_issues, user: RequestStore.store[:current_user]) ||
      issues&.first && issues.first[:request_issue_ids]
  end

  def create_remand_reasons(decision_issue, remand_reasons_attrs)
    fail_if_no_remand_reasons!(decision_issue, remand_reasons_attrs)
    remand_reasons_attrs.each do |attrs|
      decision_issue.remand_reasons.find_or_initialize_by(code: attrs[:code]).tap do |record|
        record.post_aoj = attrs[:post_aoj]
        record.save!
      end
    end
  end

  # Delete this method when feature flag 'ama_decision_issues' is enabled for all
  def update_issue_dispositions_deprecated!
    fail_if_invalid_issues_attrs!

    (issues || []).each do |issue_attrs|
      request_issue = appeal.request_issues.find_by(id: issue_attrs[:id]) if appeal
      next unless request_issue

      request_issue.update(disposition: issue_attrs[:disposition])

      # If disposition was remanded and now is changed to another dispostion,
      # delete all remand reasons associated with the request issue
      update_remand_reasons_deprecated(request_issue, issue_attrs[:remand_reasons] || [])
    end
  end

  # Delete this method when feature flag 'ama_decision_issues' is enabled for all
  def update_remand_reasons_deprecated(request_issue, remand_reasons_attrs)
    fail_if_no_remand_reasons!(request_issue, remand_reasons_attrs)
    remand_reasons_attrs.each do |remand_reason_attrs|
      request_issue.remand_reasons.find_or_initialize_by(code: remand_reason_attrs[:code]).tap do |record|
        record.post_aoj = remand_reason_attrs[:post_aoj]
        record.save!
      end
    end
    # Delete remand reasons that are not part of the request
    existing_codes = request_issue.reload.remand_reasons.pluck(:code)
    codes_to_delete = existing_codes - remand_reasons_attrs.pluck(:code)
    request_issue.remand_reasons.where(code: codes_to_delete).delete_all
  end
end
