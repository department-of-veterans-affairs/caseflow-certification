class Appeal < AmaReview
  validates :receipt_date, :docket_type, presence: { message: "blank" }, on: :intake_review
  validate :validate_receipt_date

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/

  def document_fetcher
    @document_fetcher ||= DocumentFetcher.new(
      appeal: self, use_efolder: true
    )
  end

  delegate :documents, :number_of_documents, :manifest_vbms_fetched_at, :manifest_vva_fetched_at, to: :document_fetcher

  def self.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(id)
    if UUID_REGEX.match(id)
      find_by_uuid!(id)
    else
      LegacyAppeal.find_or_create_by_vacols_id(id)
    end
  end

  def create_issues!(request_issues_data:)
    request_issues.destroy_all unless request_issues.empty?

    request_issues_data.map { |data| request_issues.create_from_intake_data!(data) }
  end

  def serializer
    ::WorkQueue::AppealSerializer
  end
end
