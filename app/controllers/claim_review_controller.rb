class ClaimReviewController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application
  helper_method :props

  def edit
    props
  rescue StandardError => e
    Raven.capture_exception(e)
    flash[:error] = e.message
  end

  def update
    if request_issues_update.perform!
      render json: {
        requestIssues: claim_review.request_issues.map(&:ui_hash)
      }
    else
      render json: { error_code: request_issues_update.error_code }, status: 422
    end
  end

  private

  def props
    @props ||= {
      userDisplayName: current_user.display_name,
      dropdownUrls: dropdown_urls,
      feedbackUrl: feedback_url,
      buildDate: build_date,
      serverIntake: higher_level_review.ui_hash,
      claimId: url_claim_id,
      featureToggles: {
        useAmaActivationDate: FeatureToggle.enabled?(:use_ama_activation_date, user: current_user)
      }
    }
  end

  def source_type
    fail "Must override source_type"
  end

  def request_issues_update
    @request_issues_update ||= RequestIssuesUpdate.new(
      user: current_user,
      review: claim_review,
      request_issues_data: params[:request_issues]
    )
  end

  def claim_review
    raise StandardError.new("oh no")
    @claim_review ||=
      EndProductEstablishment.find_by!(reference_id: url_claim_id, source_type: source_type).source
  end

  def url_claim_id
    params.permit(:claim_id)[:claim_id]
  end

  helper_method :url_claim_id

  def set_application
    RequestStore.store[:application] = "intake"
  end

  def verify_access
    verify_authorized_roles("Mail Intake", "Admin Intake")
  end

  def verify_feature_enabled
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:intake)
  end
end
