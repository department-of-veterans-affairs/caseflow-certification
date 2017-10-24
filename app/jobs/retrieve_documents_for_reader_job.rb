# This job will retrieve cases from VACOLS via the AppealRepository
# and all documents for these cases in VBMS and store them
class RetrieveDocumentsForReaderJob < ActiveJob::Base
  queue_as :low_priority

  DEFAULT_USERS_LIMIT = 10
  def perform(args = {})
    RequestStore.store[:application] = "reader"

    # specified limit of users we fetch for
    limit = args["limit"] || DEFAULT_USERS_LIMIT
    find_all_reader_users_by_documents_fetched_at(limit).each do |user|
      start_fetch_job(user)
    end
  end

  def start_fetch_job(user)
    if Rails.env.development? || Rails.env.test?
      FetchDocumentsForReaderUserJob.perform_now(user)
    else
      # in prod, we run this asynchronously.
      # Through shoryuken we retry and have exponential backoff
      FetchDocumentsForReaderUserJob.perform_later(user)
    end
  end

  def find_all_reader_users_by_documents_fetched_at(limit = 10)
    ReaderUser.all_by_documents_fetched_at(limit)
  end
end
