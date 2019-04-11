# frozen_string_literal: true

class AppealsController < ApplicationController
  before_action :react_routed
  before_action :set_application, only: [:document_count]
  # Only whitelist endpoints VSOs should have access to.
  skip_before_action :deny_vso_access, only: [:index, :power_of_attorney, :show_case_list, :show, :veteran, :hearings]

  def index
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        veteran_file_number = request.headers["HTTP_VETERAN_ID"]

        result = CaseSearchResultsForVeteranFileNumber.new(
          file_number: veteran_file_number, user: current_user
        ).call

        render_search_results_as_json(result)
      end
    end
  end

  def show_case_list
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        result = CaseSearchResultsForCaseflowVeteranId.new(
          caseflow_veteran_id: params[:caseflow_veteran_id], user: current_user
        ).call

        render_search_results_as_json(result)
      end
    end
  end

  def document_counts_by_id
    render json: { document_counts_by_id: build_document_counts_hash }
  rescue Caseflow::Error::EfolderAccessForbidden => error
    render(error.serialize_response)
  end

  def build_document_counts_hash
    document_counts_by_id_hash = {}
    params[:appeal_ids].split(",").each do |appeal_id|
      begin
        document_counts_by_id_hash[appeal_id] =
          Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(appeal_id)
          .number_of_documents
      rescue StandardError => error
        document_counts_by_id_hash[appeal_id] = error
        next
      end
    end
    document_counts_by_id_hash
  end

  def power_of_attorney
    render json: {
      representative_type: appeal.representative_type,
      representative_name: appeal.representative_name,
      representative_address: appeal.representative_address
    }
  end

  def hearings_by_id
    log_hearings_request
    render json: { most_recently_held_hearings_by_id: build_most_recently_held_hearings_hash }
  end

  def build_most_recently_held_hearings_hash
    most_recently_held_hearings_by_id_hash = {}
    params[:appeal_ids].split(",").each do |appeal_id|
      begin
        most_recently_held_hearings_by_id_hash[appeal_id] = HearingRepository
          .build_hearing_object_for_appeal(most_recently_held_hearing(appeal_id))
      rescue StandardError => error
        most_recently_held_hearings_by_id_hash[appeal_id] = error
        next
      end
    end
    most_recently_held_hearings_by_id_hash
  end

  def most_recently_held_hearing(appeal_id)
    @most_recently_held_hearing =
      Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(appeal_id)
        .hearings
        .select { |hearing| hearing.disposition.to_s == Constants.HEARING_DISPOSITION_TYPES.held }
        .max_by(&:scheduled_for)
  end

  # For legacy appeals, veteran address and birth/death dates are
  # the only data that is being pulled from BGS, the rest are from VACOLS for now
  def veteran
    render json: {
      veteran: ::WorkQueue::VeteranSerializer.new(appeal).serializable_hash[:data][:attributes]
    }
  end

  def show
    no_cache
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        if BGSService.new.can_access?(appeal.veteran_file_number)
          id = params[:appeal_id]
          MetricsService.record("Get appeal information for ID #{id}",
                                service: :queue,
                                name: "AppealsController.show") do
            render json: { appeal: json_appeals(appeal)[:data] }
          end
        else
          render(Caseflow::Error::ActionForbiddenError.new.serialize_response)
        end
      end
    end
  end

  helper_method :appeal, :url_appeal_uuid

  def appeal
    @appeal ||= Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def url_appeal_uuid
    params[:appeal_id]
  end

  def update
    if request_issues_update.perform!
      flash[:removed] = review_removed_message if request_issues_update.after_issues.empty?
      render json: {
        issuesBefore: request_issues_update.before_issues.map(&:ui_hash),
        issuesAfter: request_issues_update.after_issues.map(&:ui_hash)
      }
    else
      render json: { error_code: request_issues_update.error_code }, status: :unprocessable_entity
    end
  end

  private

  # :reek:DuplicateMethodCall { allow_calls: ['result.extra'] }
  # :reek:FeatureEnvy
  def render_search_results_as_json(result)
    if result.success?
      render json: result.extra[:search_results]
    else
      render json: result.to_h, status: result.extra[:status]
    end
  end

  def log_hearings_request
    # Log requests to this endpoint to try to investigate cause addressed by this rollback:
    # https://github.com/department-of-veterans-affairs/caseflow/pull/9271
    DataDogService.increment_counter(
      metric_group: "request_counter",
      metric_name: "hearings_for_appeal",
      app_name: RequestStore[:application]
    )
  end

  def request_issues_update
    @request_issues_update ||= RequestIssuesUpdate.new(
      user: current_user,
      review: appeal,
      request_issues_data: params[:request_issues]
    )
  end

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def json_appeals(appeal)
    if appeal.is_a?(Appeal)
      WorkQueue::AppealSerializer.new(appeal, params: { user: current_user }).serializable_hash
    elsif appeal.is_a?(LegacyAppeal)
      WorkQueue::LegacyAppealSerializer.new(appeal, params: { user: current_user }).serializable_hash
    end
  end

  def review_removed_message
    claimant_name = appeal.veteran_full_name
    "You have successfully removed #{appeal.class.review_title} for #{claimant_name}
    (ID: #{appeal.veteran_file_number})."
  end
end
