class AddCommentToTableAndColumn < ActiveRecord::Migration[5.1]
  def change
    change_column_comment(:appeals, :docket_type, "The docket type selected by the Veteran on their Appeal form, which can be Hearing, Evidence Submission, or Direct Review.")
    change_column_comment(:appeals, :established_at, "The datetime at which the Appeal has successfully been intaken into Caseflow.")
    change_column_comment(:appeals, :legacy_opt_in_approved, "Selected by the Claims Assistant during intake.  Indicates whether a Veteran opted to withdraw their matching issues from the legacy process when submitting them for an AMA Decision Review. If there is a matching legacy issue, and it is not withdrawn, then it is ineligible for the AMA Decision Review.")
    change_column_comment(:appeals, :receipt_date, "The date that an Appeal form was received. This is used to determine which issues are within the timeliness window to be appealed, and which issues to not show because they are in the future of when this form was received.")
    change_column_comment(:appeals, :uuid, "The universally unique identifier for the appeal, which can be used to navigate to appeals/appeal_uuid")
    change_column_comment(:appeals, :veteran_is_not_claimant, "Selected by the Claims Assistant during intake, indicates whether the Veteran is the claimant, or if the claimant is someone else like a spouse or a child. Must be TRUE if Veteran is deceased.")
    change_column_comment(:claimants, :participant_id, "The participant ID for the claimant selected on a Decision Review.")
    change_column_comment(:claimants, :payee_code, "The payee_code for the claimant selected on a Decision Review, if applicable. Payee_code is required for claimants that are not the Veteran, when the claim is processed in VBMS.")
    change_column_comment(:claimants, :review_request_id, "The ID of the Decision Review the claimant is on.")
    change_column_comment(:claimants, :review_request_type, "The type of Decision Review the claimant is on.")
    change_column_comment(:decision_issues, :benefit_type, "The Benefit Type, also known as the Line of Business for a decision issue. For example, compensation, pension, or education.")
    change_column_comment(:decision_issues, :caseflow_decision_date, "This is a decision date for decision issues where decisions are entered in Caseflow, such as for Appeals or for Decision Reviews with a business line that is not processed in VBMS.")
    change_column_comment(:decision_issues, :disposition, "The disposition for a decision issue, for example 'granted' or 'denied'.")
    change_column_comment(:decision_issues, :end_product_last_action_date, "After an End Product gets synced with a status of CLR (cleared), we save the End Product's last_action_date on any Decision Issues that are created as a result. We use this as a proxy for decision date for non-rating issues that were processed in VBMS because they don't have a rating profile date, and we do not have access to the exact decision date.")
    change_column_comment(:decision_issues, :profile_date, "If a decision issue is connected to a rating, this is the profile_date of that rating. The profile_date is used as an identifier for the rating, and is the date we believe that the Veterans think of as the decision date.")
    change_column_comment(:decision_issues, :promulgation_date, "If a decision issue is connected to a rating, it will have a promulgation date. This represents the date that the decision is legally official. It is different than the decision date. It is used for calculating whether a decision issue is within the timeliness window to be appealed or get a higher level review.")
    change_column_comment(:decision_issues, :rating_issue_reference_id, "If the decision issue is connected to the rating, this ID identifies the specific issue on the rating that is connected to the decision issue (a rating can have multiple issues). This is unique per rating issue.")
    change_column_comment(:end_product_establishments, :benefit_type_code, "The benefit_type_code is 1 if the Veteran is alive, and 2 if the Veteran is deceased. Not to be confused with benefit_type, which is unrelated.")
    change_column_comment(:end_product_establishments, :claim_date, "The claim_date for End Products established is set to the receipt date of the form.")
    change_column_comment(:end_product_establishments, :claimant_participant_id, "The participant ID of the claimant submitted on the End Product.")
    change_column_comment(:end_product_establishments, :code, "The end product code, which determines the type of end product that is established. For example, it can contain information about whether it is rating, nonrating, compensation, pension, created automatically due to a Duty to Assist Error, and more.")
    change_column_comment(:end_product_establishments, :development_item_reference_id, "When a Veteran requests an informal conference with their Higher Level Review, a tracked item is created. This stores the ID of the of the tracked item, it is also used to indicate the success of creating the tracked item.")
    change_column_comment(:end_product_establishments, :doc_reference_id, "When a Veteran requests an informal conference, a claimant letter is generated. This stores the document ID of the claimant letter, and is also used to track the success of creating the claimant letter.")
    change_column_comment(:end_product_establishments, :last_synced_at, "The time that the status of the End Product was last synced with BGS. Once an End Product is cleared or canceled, it will stop being synced.")
    change_column_comment(:end_product_establishments, :modifier, "The end product modifier. For Higher Level Reviews, the modifiers range from 030-039. For Supplemental Claims, they range from 040-049. The same modifier cannot be used twice for an active end product per Veteran.  Once an End Product is no longer active, the modifier can be used again.")
    change_column_comment(:end_product_establishments, :reference_id, "The claim_id of the End Product, which is stored after the End Product is successfully established in VBMS")
    change_column_comment(:end_product_establishments, :source_id, "The ID of the Decision Review that the end product establishment is connected to.")
    change_column_comment(:end_product_establishments, :source_type, "The type of Decision Review that the End Product Establishment is for, for example HigherLevelReview.")
    change_column_comment(:end_product_establishments, :synced_status, "The status of the End Product, which is synced by a job. Once and End Product is Cleared (CLR) or (CAN), it stops getting synced because the status will no longer change")
    change_column_comment(:end_product_establishments, :user_id, "The ID of the user who performed the Decision Review Intake connected to this End Product Establishment.")
    change_column_comment(:higher_level_reviews, :establishment_attempted_at, "A timestamp for the most recent attempt at establishing a claim.")
    change_column_comment(:higher_level_reviews, :establishment_error, "The error captured while trying to establish a claim asynchronously.  This error gets removed once establishing the claim succeeds.")
    change_column_comment(:higher_level_reviews, :establishment_submitted_at, "Timestamp for when an intake for a Decision Review finished being intaken by a Claim Assistant.")
    change_column_comment(:higher_level_reviews, :informal_conference, "Indicates whether a Veteran selected on their Higher Level Review form to have an informal conference.")
    change_column_comment(:higher_level_reviews, :legacy_opt_in_approved, "Selected by the Claims Assistant during intake.  Indicates whether a Veteran opted to withdraw their matching issues from the legacy process when submitting them for an AMA Decision Review. If there is a matching legacy issue, and it is not withdrawn, then it is ineligible for the AMA Decision Review.")
    change_column_comment(:higher_level_reviews, :receipt_date, "The date that the Higher Level Review form was received. This is used to determine which issues are within the timeliness window to be appealed, and which issues to not show because they are in the future of when this form was received.  It is also the claim date for any associated end products that are established.")
    change_column_comment(:higher_level_reviews, :same_office, "Whether the Veteran wants their issues to be reviewed by the same office where they were previously reviewed. This creates a special issue on all of the contentions created on this Higher Level Review.")
    change_column_comment(:higher_level_reviews, :veteran_is_not_claimant, "Selected by the Claims Assistant during intake, indicates whether the Veteran is the claimant, or if the claimant is someone else like a spouse or a child. Must be TRUE if Veteran is deceased.")
    change_column_comment(:intakes, :cancel_other, "The additional notes a Claims Assistant can enter if they are canceling an intake for a reason other than the options presented.")
    change_column_comment(:intakes, :cancel_reason, "The reason a Claim Assistant is canceling the current intake. Intakes can also be canceled automatically when there is an uncaught error, with the reason 'system_error'.")
    change_column_comment(:intakes, :detail_id, "The ID of the Decision Review that the Intake is connected to.")
    change_column_comment(:legacy_issue_optins, :optin_processed_at, "The timestamp for when the opt-in was successfully processed.")
    change_column_comment(:legacy_issue_optins, :original_disposition_code, "The original disposition code of the VACOLS issue being opted in. Stored in case the opt-in is rolled back.")
    change_column_comment(:legacy_issue_optins, :original_disposition_date, "The original disposition date of the VACOLS issue being opted in. Stored in case the opt-in is rolled back.")
    change_column_comment(:legacy_issue_optins, :request_issue_id, "The request issue connected to the legacy VACOLS issue that has been opted in.")
    change_column_comment(:legacy_issue_optins, :rollback_created_at, "Timestamp for when the connected request issue is removed from a Decision Review during edit, indicating that the opt-in needs to be rolled back.")
    change_column_comment(:legacy_issue_optins, :rollback_processed_at, "Timestamp for when a rolled back opt-in has successfully finished being rolled back.")
    change_column_comment(:ramp_closed_appeals, :partial_closure_issue_sequence_ids, "The VACOLS sequence IDs of issues for the legacy appeal with the given VACOLS ID that have been closed because they've been opted into RAMP.")
    change_column_comment(:ramp_closed_appeals, :ramp_election_id, "The id of the RAMP election that caused the given legacy appeal to be closed.")
    change_column_comment(:ramp_closed_appeals, :vacols_id, "The VACOLS ID of the legacy appeal that has been closed / opted-in to RAMP.")
    change_column_comment(:ramp_elections, :end_product_reference_id, "The claim_id of the end product that was established as a result of this RAMP election.")
    change_column_comment(:ramp_elections, :end_product_status, "The status of the end product that was established as a result of this RAMP election.")
    change_column_comment(:ramp_elections, :end_product_status_last_synced_at, "Timestamp for when the status of the end product was last synced. An end product will get synced until it is cleared or canceled.")
    change_column_comment(:ramp_elections, :established_at, "Timestamp for when the end product was successfully established in VBMS.")
    change_column_comment(:ramp_elections, :establishment_attempted_at, "Timestamp for the most recent attempt at establishing an end product in VBMS.")
    change_column_comment(:ramp_elections, :establishment_error, "The error captured while trying to establish a claim asynchronously.  This error gets removed once establishing the claim succeeds.")
    change_column_comment(:ramp_elections, :establishment_submitted_at, "Timestamp for when an intake for a RAMP Election finished being intaken by a Claim Assistant.")
    change_column_comment(:ramp_elections, :notice_date, "The date that the Veteran was notified of their option to opt their legacy appeals into RAMP.")
    change_column_comment(:ramp_refilings, :end_product_reference_id, "The claim_id of the end product that was established as a result of this RAMP refiling.")
    change_column_comment(:ramp_refilings, :establishment_attempted_at, "A timestamp for the most recent attempt at establishing a claim.")
    change_column_comment(:ramp_refilings, :establishment_error, "The error captured while trying to establish a claim asynchronously.  This error gets removed once establishing the claim succeeds.")
    change_column_comment(:ramp_refilings, :establishment_submitted_at, "Timestamp for when an intake for a Decision Review finished being intaken by a Claim Assistant.")
    change_column_comment(:request_issues, :end_product_establishment_id, "The ID of the End Product Establishment created for this request issue.")
    change_column_comment(:request_issues, :ineligible_due_to_id, "If a request issue is ineligible due to another request issue, for example that issue is already being actively reviewed, then the ID of the other request issue is stored here.")
    change_column_comment(:request_issues, :ineligible_reason, "The reason for a Request Issue being ineligible. If a Request Issue has an ineligible_reason, it is still captured, but it will not get a contention in VBMS or a decision.")
    change_column_comment(:request_issues, :issue_category, "The category selected for nonrating request issues. These vary by business line (also known as benefit type).")
    change_column_comment(:request_issues, :notes, "Notes added by the Claims Assistant when adding request issues. This may be used to capture handwritten notes on the form, or other comments the CA wants to capture.")
    change_column_comment(:request_issues, :ramp_claim_id, "If a rating issue was created as a result of an issue intaken for a RAMP Review, it will be connected to the former RAMP issue by its End Product's claim ID.")
    change_column_comment(:request_issues, :removed_at, "When a request issue is removed from a Decision Review during an edit, if it has a contention in VBMS that is also removed. This field indicates when the contention has successfully been removed in VBMS.")
    change_column_comment(:request_issues, :untimely_exemption, "If the contested issue's decision date was more than a year before the receipt date, it is considered untimely (unless it is a Supplemental Claim). However, an exemption to the timeliness can be requested. If so, it is indicated here.")
    change_column_comment(:request_issues, :untimely_exemption_notes, "Notes related to the untimeliness exemption requested.")
    change_column_comment(:request_issues, :vacols_id, "The vacols_id of the legacy appeal that had an issue found to match the request issue.")
    change_column_comment(:request_issues, :vacols_sequence_id, "The vacols_sequence_id, for the specific issue on the legacy appeal which the Claims Assistant determined to match the request issue on the Decision Review. A combination of the vacols_id (for the legacy appeal), and vacols_sequence_id (for which issue on the legacy appeal), is required to identify the issue being opted-in.")
    change_column_comment(:request_issues_updates, :after_request_issue_ids, "An array of the Request Issue IDs after a user has finished editing a Decision Review. Used with before_request_issue_ids to determine appropriate actions (such as which contentions need to be added or removed).")
    change_column_comment(:request_issues_updates, :before_request_issue_ids, "An array of the Request Issue IDs previously on the Decision Review before this editing session. Used with after_request_issue_ids to determine appropriate actions (such as which contentions need to be added or removed).")
    change_column_comment(:request_issues_updates, :review_id, "The ID of the Decision Review that was edited.")
    change_column_comment(:request_issues_updates, :user_id, "The ID of the user who edited the Decision Review.")
    change_column_comment(:supplemental_claims, :benefit_type, "The benefit type selected by the Veteran on their form, also known as a Line of Business.")
    change_column_comment(:supplemental_claims, :decision_review_remanded_id, "If the supplemental claim was automatically generated due to a remanded disposition, including duty to assist errors, then the ID of the original Decision Review is stored here.")
    change_column_comment(:supplemental_claims, :decision_review_remanded_type, "The type of the Decision Review remanded if applicable.")
    change_column_comment(:supplemental_claims, :establishment_attempted_at, "A timestamp for the most recent attempt at establishing a claim.")
    change_column_comment(:supplemental_claims, :establishment_error, "The error captured while trying to establish a claim asynchronously.  This error gets removed once establishing the claim succeeds.")
    change_column_comment(:supplemental_claims, :legacy_opt_in_approved, "Selected by the Claims Assistant during intake.  Indicates whether a Veteran opted to withdraw their matching issues from the legacy process when submitting them for an AMA Decision Review. If there is a matching legacy issue, and it is not withdrawn, then it is ineligible for the AMA Decision Review.")
    change_column_comment(:supplemental_claims, :receipt_date, "The date that the Supplemental Claim form was received. This is used to determine which issues to not show because they are in the future of when this form was received.  It is also the claim date for any associated end products that are established.")
    change_column_comment(:supplemental_claims, :veteran_is_not_claimant, "Selected by the Claims Assistant during intake, indicates whether the Veteran is the claimant, or if the claimant is someone else like a spouse or a child. Must be TRUE if Veteran is deceased.")
    change_column_comment(:tasks, :appeal_id, "The ID of the Decision Review the task is being created on, which might not be an Appeal.")
    change_column_comment(:tasks, :appeal_type, "Indicates the type of DecisionReview that is connected. This can be an Appeal, HigherLevelReview, or SupplementalClaim.")

    change_table_comment(:appeals, "A table for the Decision Reviews intaken for Appeals to the Board.")
    change_table_comment(:board_grant_effectuations, "BoardGrantEffectuation represents the work item of updating records in response to a granted issue on a Board appeal. Some are represented as contentions on an EP in VBMS. Others are tracked via Caseflow tasks.")
    change_table_comment(:claimants, "The claimant for each Decision Review, and its payee_code if required")
    change_table_comment(:decision_issues, "Issues that represent a decision made on a Decision Review's request_issue.")
    change_table_comment(:end_product_establishments, "Keeps track of End Products that need to be established for AMA Decision Review Intakes, when they are successfully established, and updates on the End Product's status")
    change_table_comment(:higher_level_reviews, "Intake data for Higher Level Reviews.")
    change_table_comment(:intakes, "Keeps track of the initial intake of all Decision Reviews and RAMP Reviews")
    change_table_comment(:legacy_issue_optins, "When a VACOLS issue from a legacy appeal is opted-in to AMA, this table keeps track of the related request_issue, and the status of processing the opt-in, or rollback if the request issue is removed from a Decision Review")
    change_table_comment(:ramp_closed_appeals, "Keeps track of legacy appeals that are closed or partially closed due to a RAMP election.")
    change_table_comment(:ramp_election_rollbacks, "If a RAMP election needs to get rolled back for some reason, for example if the EP is canceled, it is tracke here. Also any VACOLS issues that were opted-in are also rolled back.")
    change_table_comment(:ramp_elections, "Intake data for RAMP Elections.")
    change_table_comment(:ramp_issues, "Keeps track of issues added to an End Product for RAMP Reviews.")
    change_table_comment(:ramp_refilings, "Intake data for RAMP Refilings, also known as RAMP Selection.")
    change_table_comment(:request_decision_issues, "Bridge table to match RequestIssues to DecisionIssues")
    change_table_comment(:request_issues, "Issues that are added to a Decision Review during Intake")
    change_table_comment(:request_issues_updates, "Keeps track of edits to request_issues on a Decision Review that happen after the initial intake, such as removing and adding issues")
    change_table_comment(:supplemental_claims, "Intake data for Supplemental Claims.")
  end
end
