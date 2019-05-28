# frozen_string_literal: true

# This job will retrieve cases from VACOLS via the AppealRepository
# and all documents for these cases in VBMS and store them
class FetchDocumentsForReaderUserJob < ApplicationJob
  queue_as :low_priority
  application_attr :reader

  def perform(reader_user)
    reader_user.update!(documents_fetched_at: Time.zone.now)
    appeals = AppealsForReaderJob.new(reader_user.user).process
    FetchDocumentsForReaderJob.new(user: reader_user.user, appeals: appeals).process
  end
end
