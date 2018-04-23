class AppealsController < ApplicationController
  def index
    return veteran_id_not_found_error unless veteran_id

    MetricsService.record("VACOLS: Get appeal information for file_number #{veteran_id}",
                          name: "QueueController.appeals") do

      begin
        appeals = Appeal.fetch_appeals_by_file_number(veteran_id)
      rescue ActiveRecord::RecordNotFound
        appeals = []
      end

      render json: {
        appeals: json_appeals(appeals)[:data]
      }
    end
  end

  # TODO: Respond to format here.
  def show
    vacols_id = params[:id]

    MetricsService.record("VACOLS: Get appeal information for VACOLS ID #{vacols_id}",
                          name: "AppealsController.show") do
      appeal = Appeal.find_or_create_by_vacols_id(vacols_id)
      render json: {
        appeal: appeal.to_hash(issues: appeal)
      }
    end
  end

    # respond_to do |format|
    #   format.html do
    #     return redirect_to "/queue" if feature_enabled?(:queue_welcome_gate)
    #     render(:index)
    #   end
    #   format.json do
    #     MetricsService.record "Get assignments for #{current_user.id}" do
    #       render json: {
    #         cases: current_user.current_case_assignments_with_views
    #       }
    #     end
    #   end
    # end

  private

  def veteran_id
    request.headers["HTTP_VETERAN_ID"]
  end

  def veteran_id_not_found_error
    render json: {
      "errors": [
        "title": "Must include Veteran ID",
        "detail": "Veteran ID should be included as HTTP_VETERAN_ID element of request headers"
      ]
    }, status: 400
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::WorkQueue::AppealSerializer
    ).as_json
  end
end
