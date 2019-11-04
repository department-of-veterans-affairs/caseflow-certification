# frozen_string_literal: true

class VirtualHearings::DeleteConferencesJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  def perform
    VirtualHearingRepository.ready_for_deletion.map do |virtual_hearing|
      process_virtual_hearing(virtual_hearing)
    end
  end

  private

  def pexip_service
    @pexip_service ||= PexipService.new(
      host: ENV["PEXIP_MANAGEMENT_NODE_HOST"],
      port: ENV["PEXIP_MANAGEMENT_NODE_PORT"],
      user_name: ENV["PEXIP_USERNAME"],
      password: ENV["PEXIP_PASSWORD"],
      client_host: ENV["PEXIP_CLIENT_HOST"]
    )
  end

  def process_virtual_hearing(virtual_hearing)
    return unless delete_conference(virtual_hearing)

    virtual_hearing.conference_deleted = true

    send_cancellation_emails(virtual_hearing) if virtual_hearing.cancelled?

    virtual_hearing.save!
  end

  # Returns whether or not the conference was deleted from Pexip
  def delete_conference(virtual_hearing)
    response = pexip_service.delete_conference(conference_id: virtual_hearing.conference_id)

    raise response.error unless response.success?

    true
  rescue Caseflow::Error::PexipNotFoundError
    # Assume the conference was already deleted if it's no longer in Pexip.
    true
  rescue Caseflow::Error::PexipApiError => error
    Rails.logger.error(
      "Failed to delete conference from Pexip with error: (#{error.code}) #{error.message}"
    )

    capture_exception(
      error: error,
      extra: {
        hearing_id: virtual_hearing.hearing_id,
        virtual_hearing_id: virtual_hearing.id,
        pexip_conference_Id: virtual_hearing.conference_id
      }
    )

    false
  end

  def send_cancellation_emails(virtual_hearing)
    if !virtual_hearing.veteran_email_sent
      # TODO: Send the email
      virtual_hearing.veteran_email_sent = true
    end

    if !virtual_hearing.judge_email_sent
      # TODO: Send the email
      virtual_hearing.judge_email_sent = true
    end

    if !virtual_hearing.representative_email.nil? && !virtual_hearing.representative_email_sent
      # TODO: Send the email
      virtual_hearing.representative_email_sent = true
    end
  end
end
