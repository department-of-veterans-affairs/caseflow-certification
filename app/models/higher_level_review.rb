class HigherLevelReview < ClaimReview
  with_options if: :saving_review do
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  has_many :dta_supplemental_claims, as: :decision_review_remanded, class_name: "SupplementalClaim"

  END_PRODUCT_MODIFIERS = %w[030 031 032 033 034 035 036 037 038 039].freeze

  def self.review_title
    Constants.INTAKE_FORM_NAMES_SHORT.higher_level_review
  end

  def ui_hash
    super.merge(
      formType: "higher_level_review",
      sameOffice: same_office,
      informalConference: informal_conference
    )
  end

  def on_decision_issues_sync_processed(_end_product_establishment)
    create_dta_supplemental_claims!
  end

  # needed for appeal status api

  def review_status_id
    "HLR#{id}"
  end

  def linked_review_ids
    Array.wrap(review_status_id)
  end

  def incomplete
    false
  end

  def active?
    hlr_ep_active? || active_dta_claims?
  end

  def description
    # need to impelement
  end

  def status_hash
    { type: fetch_status }
  end

  def alerts
    # need to implement. add logic to return alert enum
  end

  def issues
    # need to implement. get request and corresponding rating issue
    []
  end

  def decision_event_date
    return if dta_supplemental_claims.any?
    return unless decision_issues.any?

    if end_product_establishments.any?
      decision_issues.first.approx_decision_date
    else
      decision_issues.first.promulgation_date
    end
  end

  def dta_error_event_date
    return if hlr_ep_active?
    return unless dta_supplemental_claims.any?

    decision_issues.with_dta_error.first.approx_decision_date
  end

  def other_close_event_date
    return if active?
    return unless decision_issues.empty?
    return unless end_product_establishments.any?

    end_product_establishments.first.last_synced_at
  end

  def events
    @events ||= AppealEvents.new(appeal: self).all
  end

  private

  def informal_conference?
    informal_conference
  end

  def new_end_product_establishment(ep_code)
    end_product_establishments.build(
      veteran_file_number: veteran_file_number,
      claim_date: receipt_date,
      payee_code: payee_code || EndProduct::DEFAULT_PAYEE_CODE,
      code: ep_code,
      claimant_participant_id: claimant_participant_id,
      station: end_product_station,
      benefit_type_code: veteran.benefit_type_code,
      user: intake_processed_by
    )
  end

  def hlr_ep_active?
    end_product_establishments.any? { |ep| ep.status_active?(sync: false) }
  end

  def fetch_status
    if hlr_ep_active?
      :hlr_received
    elsif active_dta_claims?
      :hlr_dta_error
    elsif dta_supplemental_claims.any?
      dta_supplemental_claims.each do |rsc|
        return :hlr_decision if rsc.decision_issues.any?
      end
      return :hlr_closed
    else
      decision_issues ? :hlr_closed : :hlr_decision
    end
  end
end
