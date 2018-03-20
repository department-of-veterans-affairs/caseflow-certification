class QueueController < ApplicationController
  before_action :react_routed, :check_queue_out_of_service
  before_action :verify_welcome_gate_access, except: :complete
  before_action :verify_queue_phase_two, only: :complete

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    render "queue/index"
  end

  def complete
    record = AttorneyCaseReview.complete!(complete_params.merge(attorney: current_user, task_id: params[:task_id]))
    return attorney_case_review_error unless record

    response = { attorney_case_review: record }
    response[:issues] = record.appeal.issues if record.type == "DraftDecision"
    render json: response
  end

  def tasks
    MetricsService.record("VACOLS: Get all tasks with appeals for #{params[:user_id]}",
                          name: "QueueController.tasks") do

      tasks, appeals = AttorneyQueue.tasks_with_appeals(params[:user_id])
      render json: {
        tasks: json_tasks(tasks),
        appeals: json_appeals(appeals)
      }
    end
  end

  def judges
    render json: { judges: Judge.list_all }
  end

  def dev_document_count
    # only used for local dev. see Appeal.number_of_documents_url
    appeal = Appeal.find_by(vbms_id: request.headers["HTTP_FILE_NUMBER"])
    render json: {
      data: {
        attributes: {
          documents: (1..appeal.number_of_documents).to_a
        }
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {}, status: 404
  end

  private

  def verify_welcome_gate_access
    # :nocov:
    return true if feature_enabled?(:queue_welcome_gate)
    code = Rails.cache.read(:queue_access_code)
    return true if params[:code] && code && params[:code] == code
    redirect_to "/unauthorized"
    # :nocov:
  end

  def attorney_case_review_error
    render json: {
      "errors": [
        "title": "Error Completing Attorney Case Review",
        "detail": "Errors occured when completing attorney case review"
      ]
    }, status: 400
  end

  def complete_params
    params.require("queue").permit(:type,
                                   :reviewing_judge_id,
                                   :document_id,
                                   :work_product,
                                   :overtime,
                                   :note,
                                   issues: [:disposition, :vacols_sequence_id,
                                            remand_reasons: [:code, :after_certification]])
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::WorkQueue::AppealSerializer
    ).as_json
  end

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::TaskSerializer
    ).as_json
  end

  def check_queue_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("queue_out_of_service")
  end
end
