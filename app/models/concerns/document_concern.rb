module DocumentConcern
  extend ActiveSupport::Concern

  # Number of documents stored locally via nightly RetrieveDocumentsForReaderJob.
  # Fall back to count from VBMS if no local documents are found.
  def number_of_documents_from_caseflow
    count = Document.where(file_number: veteran_file_number).size
    (count != 0) ? count : number_of_documents
  end

  # Retrieves any documents that have been uploaded more recently than the user has viewed
  # the appeal or an optional provided date
  def new_documents_for_user(user, placed_on_hold_timestamp = nil)
    caseflow_documents = Document.where(file_number: veteran_file_number)
    if caseflow_documents.empty?
      find_or_create_documents!
      caseflow_documents = Document.where(file_number: veteran_file_number)
    end

    appeal_view = appeal_views.find_by(user: user)
    return caseflow_documents if !appeal_view && !placed_on_hold_timestamp

    placed_on_hold_at = placed_on_hold_timestamp ? DateTime.strptime(placed_on_hold_timestamp, "%s") : Time.zone.at(0)
    compare_date = appeal_view ? [placed_on_hold_at, appeal_view.last_viewed_at].max : placed_on_hold_at

    filter_docs_by_date(caseflow_documents, compare_date)
  end

  def filter_docs_by_date(documents, date)
    documents.select do |doc|
      next if doc.upload_date.nil?

      doc.upload_date > date
    end
  end
end
