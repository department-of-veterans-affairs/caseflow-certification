class AddRequestIssuesComments < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:request_issues, "Each Request Issue represents the Veteran's response to a Rating Issue. Request Issues come in three flavors: rating, nonrating, and unidentified. They are attached to a Decision Review and (for those that track contentions) an End Product Establishment. A Request Issue can contest a rating issue, a decision issue, or a nonrating issue without a decision issue.")

    change_column_comment(:request_issues, :benefit_type, "The Line of Business the issue is connected with.")
    change_column_comment(:request_issues, :closed_at, "Timestamp when the request issue was closed. The reason it was closed is in closed_status.")
    change_column_comment(:request_issues, :closed_status, "Indicates whether the request issue is closed, for example if it was removed from a Decision Review, the associated End Product got canceled, the Decision Review was withdrawn.")
    change_column_comment(:request_issues, :contention_reference_id, "The ID of the contention created on the End Product for this request issue. This is populated after the contention is created in VBMS.")
    change_column_comment(:request_issues, :contention_removed_at, "When a request issue is removed from a Decision Review during an edit, if it has a contention in VBMS that is also removed. This field indicates when the contention has successfully been removed in VBMS.")
    change_column_comment(:request_issues, :contested_decision_issue_id, "The ID of the decision issue that this request issue contests. A Request issue will contest either a rating issue or a decision issue")
    change_column_comment(:request_issues, :contested_issue_description, "Description of the contested rating or decision issue. Will be either a rating issue's decision text or a decision issue's description.")
    change_column_comment(:request_issues, :contested_rating_issue_diagnostic_code, "If the contested issue is a rating issue, this is the rating issue's diagnostic code. Will be nil if this request issue contests a decision issue.")
    change_column_comment(:request_issues, :contested_rating_issue_profile_date, "If the contested issue is a rating issue, this is the rating issue's profile date. Will be nil if this request issue contests a decision issue.")
    change_column_comment(:request_issues, :contested_rating_issue_reference_id, "If the contested issue is a rating issue, this is the rating issue's reference id. Will be nil if this request issue contests a decision issue.")
    change_column_comment(:request_issues, :created_at, "Automatic timestamp when row was created")
    change_column_comment(:request_issues, :decision_date, "Either the rating issue's promulgation date or the decision issue's approx decision date")
    change_column_comment(:request_issues, :decision_review_id, "ID of the decision review that this request issue belongs to")
    change_column_comment(:request_issues, :decision_review_type, "Class name of the decision review that this request issue belongs to")
    change_column_comment(:request_issues, :decision_sync_attempted_at, "Async job processing last attempted timestamp")
    change_column_comment(:request_issues, :decision_sync_error, "Async job processing last error message")
    change_column_comment(:request_issues, :decision_sync_last_submitted_at, "Async job processing most recent start timestamp")
    change_column_comment(:request_issues, :decision_sync_processed_at, "Async job processing completed timestamp")
    change_column_comment(:request_issues, :decision_sync_submitted_at, "Async job processing start timestamp")
    change_column_comment(:request_issues, :end_product_establishment_id, "The ID of the End Product Establishment created for this request issue.")
    change_column_comment(:request_issues, :ineligible_due_to_id, "If a request issue is ineligible due to another request issue, for example that issue is already being actively reviewed, then the ID of the other request issue is stored here.")
    change_column_comment(:request_issues, :ineligible_reason, "The reason for a Request Issue being ineligible. If a Request Issue has an ineligible_reason, it is still captured, but it will not get a contention in VBMS or a decision.")
    change_column_comment(:request_issues, :is_unidentified, "Indicates whether a Request Issue is unidentified, meaning it wasn't found in the list of contestable issues, and is not a new nonrating issue. Contentions for unidentified issues are created on a rating End Product if processed in VBMS but without the issue description, and someone is required to edit it in Caseflow before proceeding with the decision.")
    change_column_comment(:request_issues, :issue_category, "The category selected for nonrating request issues. These vary by business line (also known as benefit type).")
    change_column_comment(:request_issues, :nonrating_issue_description, "The user entered description if the issue is a nonrating issue")
    change_column_comment(:request_issues, :notes, "Notes added by the Claims Assistant when adding request issues. This may be used to capture handwritten notes on the form, or other comments the CA wants to capture.")
    change_column_comment(:request_issues, :ramp_claim_id, "If a rating issue was created as a result of an issue intaken for a RAMP Review, it will be connected to the former RAMP issue by its End Product's claim ID.")
    change_column_comment(:request_issues, :rating_issue_associated_at, "Timestamp when a contention and its contested rating issue are associated in VBMS.")
    change_column_comment(:request_issues, :unidentified_issue_text, "User entered description if the request issue is neither a rating or a nonrating issue")
    change_column_comment(:request_issues, :untimely_exemption, "If the contested issue's decision date was more than a year before the receipt date, it is considered untimely (unless it is a Supplemental Claim). However, an exemption to the timeliness can be requested. If so, it is indicated here.")
    change_column_comment(:request_issues, :untimely_exemption_notes, "Notes related to the untimeliness exemption requested.")
    change_column_comment(:request_issues, :updated_at, "Automatic timestamp whenever the record changes.")
    change_column_comment(:request_issues, :vacols_id, "The vacols_id of the legacy appeal that had an issue found to match the request issue.")
    change_column_comment(:request_issues, :vacols_sequence_id, "The vacols_sequence_id, for the specific issue on the legacy appeal which the Claims Assistant determined to match the request issue on the Decision Review. A combination of the vacols_id (for the legacy appeal), and vacols_sequence_id (for which issue on the legacy appeal), is required to identify the issue being opted-in.")
    change_column_comment(:request_issues, :veteran_participant_id, "The veteran participant ID. This should be unique in upstream systems and used in the future to reconcile duplicates.")
  end
end
