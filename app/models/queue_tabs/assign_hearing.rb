# frozen_string_literal: true

##
# A version of QueueTab except it accounts only for Assign Hearings Table.
# Acts as a general tab for the two tabs for the table: amaAssignHearingTab,
# and legacyAssignHearingTab which are paginated.

class AssignHearing
  attr_accessor :regional_office_key, :appeal_type

  def initialize(appeal_type:, regional_office_key:)
    @appeal_type = appeal_type
    @regional_office_key = regional_office_key
  end

  # return schedule hearing tasks joined with CachedAppeal selected
  # by regional office
  def tasks
    @tasks ||=
      ScheduleHearingTask
        .includes(*task_includes)
        .active
        .where(appeal_type: appeal_type)
        .joins(CachedAppeal.left_join_from_tasks_clause)
        .where("cached_appeal_attributes.closest_regional_office_key = ?", regional_office_key)
  end

  def to_hash
    { columns: columns }
  end

  # return filter options for columns
  def columns
    [
      {
        name: Constants.QUEUE_CONFIG.POWER_OF_ATTORNEY_COLUMN_NAME,
        filter_options: power_of_attorney_name_options
      },
      {
        name: Constants.QUEUE_CONFIG.SUGGESTED_HEARING_LOCATION_COLUMN_NAME,
        filter_options: suggested_location_options
      }
    ]
  end

  def power_of_attorney_name_options
    tasks.joins(CachedAppeal.left_join_from_tasks_clause)
      .group(:power_of_attorney_name).count.each_pair.map do |option, count|
      label = QueueColumn.format_option_label(option, count)
      QueueColumn.filter_option_hash(option, label)
    end
  end

  def suggested_location_options
    tasks.joins(CachedAppeal.left_join_from_tasks_clause)
      .group(:suggested_hearing_location).count.each_pair.map do |option, count|
      label = QueueColumn.format_option_label(option, count)
      QueueColumn.filter_option_hash(option, label)
    end
  end

  def task_includes
    [
      { appeal: [:available_hearing_locations, :claimants] },
      { attorney_case_reviews: [:attorney] },
      :assigned_by,
      :assigned_to,
      :children,
      :parent
    ]
  end
end
