class ScheduleHearingTask < GenericTask
  class << self
    def create_from_params(params, current_user)
      root_task = RootTask.find_or_create_by!(appeal: params[:appeal])
      params[:parent_id] = root_task.id

      task_payloads = params.delete(:business_payloads)
      child_task = super(params, current_user)
      child_task.task_business_payloads.create(task_payloads) if task_payloads

      child_task
    end

    def tasks_for_ro(regional_office)
      # Get all legacy tasks for this RO
      legacy_appeal_tasks = AppealRepository.appeals_ready_for_hearing_schedule(regional_office).map do |appeal|
        ScheduleHearingTask.new(
          appeal: appeal,
          status: Constants.TASK_STATUSES.in_progress.to_sym,
          assigned_to: HearingsManagement.singleton
        )
      end

      # Get all tasks associated with AMA appeals and the regional_office
      appeal_tasks = ScheduleHearingTask.where(appeal_type: Appeal.name).joins("INNER JOIN appeals ON appeals.id = appeal_id")
        .joins("INNER JOIN veterans ON appeals.veteran_file_number = veterans.file_number")
        .where("veterans.closest_regional_office = ?", regional_office)

      legacy_appeal_tasks + appeal_tasks
    end
  end

  def update_from_params(params, current_user)
    verify_user_can_update!(current_user)

    task_payloads = params.delete(:business_payloads)
    hearing_date = task_payloads[:values][:hearing_date]
    new_date = Time.use_zone("Eastern Time (US & Canada)") do
      Time.zone.parse(hearing_date)
    end
    task_payloads[:values][:hearing_date] = new_date

    if !task_business_payloads.empty?
      task_business_payloads.update(task_payloads)
    else
      task_business_payloads.create(task_payloads)
    end

    super(params, current_user)
  end

  def update_parent_status
    hearing_pkseq = task_business_payloads[0].values["hearing_pkseq"]
    hearing_type = task_business_payloads[0].values["hearing_type"]
    hearing_date = Time.zone.parse(task_business_payloads[0].values["hearing_date"])
    hearing_date_str = "#{hearing_date.year}-#{hearing_date.month}-#{hearing_date.day} " \
                       "#{format('%##d', hearing_date.hour)}:#{format('%##d', hearing_date.min)}:00"

    if hearing_type == LegacyHearing::CO_HEARING
      HearingRepository.update_co_hearing(hearing_date_str, appeal)
    else
      HearingRepository.create_child_video_hearing(hearing_pkseq, hearing_date, appeal)
    end

    AppealRepository.update_location!(appeal, location_based_on_hearing_type(hearing_type))

    super
  end

  def location_based_on_hearing_type(hearing_type)
    if hearing_type == LegacyHearing::CO_HEARING
      LegacyAppeal::LOCATION_CODES[:awaiting_co_hearing]
    else
      LegacyAppeal::LOCATION_CODES[:awaiting_video_hearing]
    end
  end

  def available_actions(user)
    if (assigned_to && assigned_to == user) || task_is_assigned_to_users_organization?(user)
      return [
        Constants.TASK_ACTIONS.SCHEDULE_VETERAN.to_h
      ]
    end

    []
  end
end
