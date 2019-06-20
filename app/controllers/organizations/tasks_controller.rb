# frozen_string_literal: true

class Organizations::TasksController < OrganizationsController
  before_action :verify_organization_access, only: [:index]
  before_action :verify_role_access, only: [:index]

  def index
    render json: {
      organization_name: organization.name,
      tasks: json_tasks(tasks),
      id: organization.id,
      is_vso: organization.is_a?(::Representative),
      queue_config: queue_config
    }
  end

  private

  def tasks
    if organization.url == "hearings-management"
      GenericQueue.new(user: organization).tasks(1000).select { |task| task.appeal.is_a?(Appeal) || task.appeal.aod }
    else
      GenericQueue.new(user: organization).tasks(400)
    end
  end

  def queue_config
    QueueConfig.new(organization: organization).to_hash_for_user(current_user)
  end

  def organization_url
    params[:organization_url]
  end

  def json_tasks(tasks)
    tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)
    params = { user: current_user }

    AmaAndLegacyTaskSerializer.new(
      tasks: tasks, params: params, ama_serializer: organization.ama_task_serializer
    ).call
  end
end
