# frozen_string_literal: true

# Early morning job that checks if the claimant meets the Advance-On-Docket age criteria.
# If criteria is satisfied, all active appeals associated with claimant will be marked as AOD.
# This job only sets aod_based_on_age to true; it does not set it from true to false (see appeal.conditionally_set_age_aod).
class SetAppealAgeAodJob < CaseflowJob
  include ActionView::Helpers::DateHelper

  def perform
    RequestStore.store[:current_user] = User.system_user

    # We expect there to be only one claimant on an appeal. Any claimant meeting the age criteria will cause AOD.
    appeals = non_aod_active_appeals.joins(claimants: :person).where("people.date_of_birth <= ?", 75.years.ago)
    detail_msg = "IDs of age-related AOD appeals: #{appeals.pluck(:id)}"

    appeals.update_all(aod_based_on_age: true, updated_at: Time.now.utc)

    log_success(detail_msg)
  rescue StandardError => error
    log_error(self.class.name, error, detail_msg)
  end

  protected

  def log_success(details)
    duration = time_ago_in_words(start_time)
    msg = "#{self.class.name} completed after running for #{duration}.\n#{details}"
    Rails.logger.info(msg)

    slack_service.send_notification("[INFO] #{msg}")
  end

  def log_error(collector_name, err, details)
    duration = time_ago_in_words(start_time)
    msg = "#{collector_name} failed after running for #{duration}. Fatal error: #{err.message}.\n#{details}"
    Rails.logger.info(msg)
    Rails.logger.info(err.backtrace.join("\n"))

    Raven.capture_exception(err, extra: { stats_collector_name: collector_name })

    slack_service.send_notification("[ERROR] #{msg}")
  end

  private

  def non_aod_active_appeals
    # `aod_based_on_age` is initially nil
    # `aod_based_on_age` being false means that it was once true (in the case where the claimant's DOB was updated)
    Appeal.active.where(aod_based_on_age: [nil, false])
  end
end
