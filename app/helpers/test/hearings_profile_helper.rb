# frozen_string_literal: true

module Test::HearingsProfileHelper
  class << self
    attr_reader :limit, :after, :user

    def profile_data(current_user = nil, *args)
      configure_helper(current_user, args)

      select_hearings

      hearings_profile
    end

    private

    def configure_helper(current_user, args)
      @user = current_user

      options = args.extract_options!
      @limit = options[:limit] || 20
      @after = options[:after] || Time.zone.local(2020, 4, 1)

      @ama_hearings_details = []
      @legacy_hearings_details = []
    end

    def select_hearings
      hearing_disposition_tasks.each do |task|
        sort_task(task)

        break if limit_has_been_reached
      end
    end

    def hearings_profile
      {
        profile: profile,
        hearings: {
          ama_hearings: ama_hearings_details,
          legacy_hearings: legacy_hearings_details
        }
      }
    end

    def hearing_disposition_tasks
      Task.active.where(type: AssignHearingDispositionTask.name).order(:id)
    end

    def sort_task(task)
      if qualified_legacy_hearing?(task) && legacy_hearings_details.count < limit
        legacy_hearings_details << hearing_detail(task.hearing)
      elsif qualified_ama_hearing?(task) && ama_hearings_details.count < limit
        ama_hearings_details << hearing_detail(task.hearing)
      end
    rescue StandardError => error
      Rails.logger.error "Test::HearingsProfileHelper error: #{error.message}"
    end

    def limit_has_been_reached
      legacy_hearings_details.count >= limit && ama_hearings_details.count >= limit
    end

    def timezone_outside_eastern?(task)
      !!(task.hearing&.regional_office&.timezone &.!= "America/New_York")
    end

    def task_is_after_time?(task)
      task&.hearing&.scheduled_for &.> after
    end

    def qualified_hearing?(task)
      timezone_outside_eastern?(task) && task_is_after_time?(task)
    end

    def qualified_legacy_hearing?(task)
      task.appeal_type == LegacyAppeal.name && qualified_hearing?(task)
    end

    def qualified_ama_hearing?(task)
      task.appeal_type == Appeal.name && qualified_hearing?(task)
    end

    def profile
      {
        current_user_css_id: user&.css_id,
        current_user_timezone: user&.timezone,
        time_zone_name: Time.zone.name,
        config_time_zone: Rails.configuration.time_zone
      }
    end

    def hearing_detail(hearing)
      {
        id: hearing.id,
        type: hearing.class.name,
        external_id: hearing.external_id,
        created_by_timezone: hearing.created_by&.timezone,
        central_office_time_string: hearing.central_office_time_string,
        scheduled_time_string: hearing.scheduled_time_string,
        scheduled_for: hearing.scheduled_for,
        scheduled_time: hearing.scheduled_time
      }
    end

    def ama_hearings_details
      @ama_hearings_details ||= []
    end

    def legacy_hearings_details
      @legacy_hearings_details ||= []
    end
  end
end
