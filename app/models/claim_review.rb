# A claim review is a short hand term to refer to either a supplemental claim or
# higher level review as defined in the Appeals Modernization Act of 2017

class ClaimReview < AmaReview
  has_many :end_product_establishments, as: :source

  self.abstract_class = true

  def issue_code(_rated)
    fail Caseflow::Error::MustImplementInSubclass
  end

  # Save issues and assign it the appropriate end product establishment.
  # Create that end product establishment if it doesn't exist.
  def create_issues!(new_issues)
    new_issues.each do |issue|
      issue.update!(end_product_establishment: end_product_establishment_for_issue(issue))
    end
  end

  # Idempotent method to create all the artifacts for this claim.
  # If any external calls fail, it is safe to call this multiple times until
  # establishment_processed_at is successfully set.
  def process_end_product_establishments!
    end_product_establishments.each do |end_product_establishment|
      end_product_establishment.perform!
      end_product_establishment.create_contentions!
      end_product_establishment.create_associated_rated_issues!
      if informal_conference?
        end_product_establishment.generate_claimant_letter!
        end_product_establishment.generate_tracked_item!
      end
      end_product_establishment.commit!
    end

    update!(establishment_processed_at: Time.zone.now)
  end

  # NOTE: Choosing not to test this method because it is fully tested in RequestIssuesUpdate.perform!
  # Hoping to figure out how to refactor this into a private method.
  def on_request_issues_update!(request_issues_update)
    process_end_product_establishments!

    request_issues_update.removed_issues.each do |request_issue|
      request_issue.end_product_establishment.remove_contention!(request_issue)
    end
  end

  def invalid_modifiers
    end_product_establishments.map(&:modifier).reject(&:nil?)
  end

  def on_sync(end_product_establishment)
    if end_product_establishment.status_cleared?
      sync_dispositions(end_product_establishment.reference_id)
      # allow higher level reviews to do additional logic on dta errors
      yield if block_given?
    end
  end

  private

  def informal_conference?
    false
  end

  def end_product_establishment_for_issue(issue)
    ep_code = issue_code(issue.rated?)
    end_product_establishments.find_by(code: ep_code) || new_end_product_establishment(ep_code)
  end

  def sync_dispositions(reference_id)
    fetch_dispositions_from_vbms(reference_id).each do |disposition|
      request_issue = matching_request_issue(disposition[:contention_id])
      request_issue.update!(disposition: disposition[:disposition])
      # allow higher level reviews to do additional logic on dta errors
      yield(disposition, request_issue) if block_given?
    end
  end

  def fetch_dispositions_from_vbms(reference_id)
    VBMSService.get_dispositions!(claim_id: reference_id)
  end

  def matching_request_issue(contention_id)
    RequestIssue.find_by!(contention_reference_id: contention_id)
  end
end
