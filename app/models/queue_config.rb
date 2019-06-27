# frozen_string_literal: true

class QueueConfig
  include ActiveModel::Model

  attr_accessor :organization

  def initialize(args)
    super

    if !organization&.is_a?(Organization)
      fail(
        Caseflow::Error::MissingRequiredProperty,
        message: "organization property must be an instance of Organization"
      )
    end
  end

  def to_hash_for_user(user)
    {
      table_title: format(COPY::ORGANIZATION_QUEUE_TABLE_TITLE, organization.name),
      active_tab: Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME,
      tasks_per_page: TaskPager::TASKS_PER_PAGE,
      use_task_pages_api: use_task_pages_api?,
      tabs: tabs.map { |tab| attach_tasks_to_tab(tab, user) }
    }
  end

  private

  def use_task_pages_api?
    FeatureToggle.enabled?(:use_task_pages_api) && organization.use_task_pages_api?
  end

  def tabs
    [
      include_tracking_tasks_tab? ? tracking_tasks_tab : nil,
      unassigned_tasks_tab,
      assigned_tasks_tab,
      completed_tasks_tab
    ].compact
  end

  def attach_tasks_to_tab(tab, user)
    task_pager = TaskPager.new(assignee: organization, tab_name: tab[:name])

    # Only return tasks in the configuration if we are using it to populate the first page of results.
    # Otherwise avoid the overhead of the additional database requests.
    tasks = use_task_pages_api? ? serialized_tasks_for_user(task_pager.paged_tasks, user) : []

    tab.merge(
      label: format(tab[:label], task_pager.total_task_count),
      tasks: tasks,
      task_page_count: task_pager.task_page_count,
      total_task_count: task_pager.total_task_count,
      task_page_endpoint_base_path: "#{organization.path}/task_pages?tab=#{tab[:name]}"
    )
  end

  def serialized_tasks_for_user(tasks, user)
    return [] if tasks.empty?

    primed_tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)

    organization.ama_task_serializer.new(
      primed_tasks,
      is_collection: true,
      params: { user: user }
    ).serializable_hash[:data]
  end

  def include_tracking_tasks_tab?
    organization.is_a?(Representative)
  end

  def tracking_tasks_tab
    {
      label: COPY::ALL_CASES_QUEUE_TABLE_TAB_TITLE,
      name: Constants.QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME,
      description: format(COPY::ALL_CASES_QUEUE_TABLE_TAB_DESCRIPTION, organization.name),
      columns: [
        Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
        Constants.QUEUE_CONFIG.ISSUE_COUNT_COLUMN,
        Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
        Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN
      ],
      allow_bulk_assign: false
    }
  end

  def unassigned_tasks_tab
    {
      label: COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE,
      name: Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME,
      description: format(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, organization.name),
      # Compact to account for the maybe absent regional office column
      columns: [
        Constants.QUEUE_CONFIG.HEARING_BADGE_COLUMN,
        Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
        Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN,
        organization.show_regional_office_in_queue? ? Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN : nil,
        Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
        Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
        Constants.QUEUE_CONFIG.DAYS_ON_HOLD_COLUMN,
        organization.is_a?(Representative) ? nil : Constants.QUEUE_CONFIG.DOCUMENT_COUNT_READER_LINK_COLUMN
      ].compact,
      allow_bulk_assign: organization.can_bulk_assign_tasks?
    }
  end

  def assigned_tasks_tab
    {
      label: COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE,
      name: Constants.QUEUE_CONFIG.ASSIGNED_TASKS_TAB_NAME,
      description: format(COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, organization.name),
      # Compact to account for the maybe absent regional office column
      columns: [
        Constants.QUEUE_CONFIG.HEARING_BADGE_COLUMN,
        Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
        Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN,
        organization.show_regional_office_in_queue? ? Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN : nil,
        Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
        Constants.QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN,
        Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
        Constants.QUEUE_CONFIG.DAYS_ON_HOLD_COLUMN
      ].compact,
      allow_bulk_assign: false
    }
  end

  def completed_tasks_tab
    {
      label: COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE,
      name: Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME,
      description: format(COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION, organization.name),
      # Compact to account for the maybe absent regional office column
      columns: [
        Constants.QUEUE_CONFIG.HEARING_BADGE_COLUMN,
        Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
        Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN,
        organization.show_regional_office_in_queue? ? Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN : nil,
        Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
        Constants.QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN,
        Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
        Constants.QUEUE_CONFIG.DAYS_ON_HOLD_COLUMN
      ].compact,
      allow_bulk_assign: false
    }
  end
end
