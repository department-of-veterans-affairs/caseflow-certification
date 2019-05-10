# frozen_string_literal: true

# Hearing Prep repository.
class HearingRepository
  class HearingDayFull < StandardError; end

  class << self
    # :nocov:
    def fetch_hearings_for_judge(css_id, is_fetching_issues = false)
      records = MetricsService.record("VACOLS: HearingRepository.fetch_hearings_for_judge: #{css_id}",
                                      service: :vacols,
                                      name: "fetch_hearings_for_judge") do
        VACOLS::CaseHearing.hearings_for_judge(css_id) +
          VACOLS::TravelBoardSchedule.hearings_for_judge_before_hearing_prep_cutoff_date(css_id)
      end
      hearings = hearings_for(MasterRecordHelper.remove_master_records_with_children(records))

      # To speed up the daily docket and the hearing worksheet page loads, we pull in issues for appeals here.
      load_issues(hearings) if is_fetching_issues
      hearings
    end

    def fetch_hearings_for_parent(hearing_day_id)
      # Implemented by call the array version of this method
      fetch_hearings_for_parents([hearing_day_id]).values.first || []
    end

    def fetch_hearings_for_parents(hearing_day_ids)
      # Get hash of hearings grouped by their hearing day ids
      hearings_for(VACOLS::CaseHearing.hearings_for_hearing_days(hearing_day_ids))
        .group_by { |hearing| hearing.hearing_day_id.to_s }
    end

    def fetch_hearings_for_parents_assigned_to_judge(hearing_day_ids, judge)
      hearings_for(VACOLS::CaseHearing.hearings_for_hearing_days_assigned_to_judge(hearing_day_ids, judge))
        .group_by { |hearing| hearing.hearing_day_id.to_s }
    end

    def load_issues(hearings)
      children_hearings = hearings.select { |h| h.master_record == false }
      issues = VACOLS::CaseIssue.descriptions(children_hearings.map(&:appeal_vacols_id))

      appeal_ids = children_hearings.map(&:appeal_id)
      worksheet_issues_for_appeals_hash = worksheet_issues_for_appeals(appeal_ids)

      hearings.map do |hearing|
        next if hearing.master_record

        issues_hash_array = issues[hearing.appeal_vacols_id] || []
        hearing_worksheet_issues = worksheet_issues_for_appeals_hash[hearing.appeal_id] || []
        next unless hearing_worksheet_issues.empty?

        issues_hash_array.map { |i| WorksheetIssue.create_from_issue(hearing.appeal, Issue.load_from_vacols(i)) }
      end
    end

    def hearings_for_appeal(appeal_vacols_id)
      hearings_for(VACOLS::CaseHearing.for_appeal(appeal_vacols_id))
    end

    def hearings_for_appeals(vacols_ids)
      hearings = VACOLS::CaseHearing.for_appeals(vacols_ids)

      hearings.update(hearings) { |_, case_hearings| hearings_for(case_hearings) }
    end

    def update_vacols_hearing!(vacols_record, hearing_hash)
      hearing_hash = HearingMapper.hearing_fields_to_vacols_codes(hearing_hash)
      vacols_record.update_hearing!(hearing_hash.merge(staff_id: vacols_record.slogid)) if hearing_hash.present?
    end

    def create_vacols_hearing(hearing_day, appeal, hearing_datetime, hearing_location_attrs)
      VACOLS::CaseHearing.create_hearing!(
        folder_nr: appeal.vacols_id,
        hearing_date: VacolsHelper.format_datetime_with_utc_timezone(hearing_datetime),
        vdkey: hearing_day.id,
        hearing_type: hearing_day.request_type,
        room: hearing_day.room,
        board_member: hearing_day.judge ? hearing_day.judge.vacols_attorney_id : nil,
        vdbvapoc: hearing_day.bva_poc
      )

      vacols_record = VACOLS::CaseHearing.for_appeal(appeal.vacols_id).find_by(vdkey: hearing_day.id)
      hearing = LegacyHearing.assign_or_create_from_vacols_record(vacols_record)

      hearing.update(hearing_location_attributes: hearing_location_attrs) unless hearing_location_attrs.nil?

      hearing
    end

    def slot_new_hearing(hearing_day_id, scheduled_time:, appeal:, hearing_location_attrs: nil)
      hearing_day = HearingDay.find(hearing_day_id)
      fail HearingDayFull if hearing_day.hearing_day_full?

      hearing_datetime = hearing_day.scheduled_for.to_datetime.change(
        hour: scheduled_time["h"].to_i,
        min: scheduled_time["m"].to_i,
        offset: scheduled_time["offset"]
      )

      hearing = if appeal.is_a?(LegacyAppeal)
                  vacols_hearing = create_vacols_hearing(hearing_day, appeal, hearing_datetime, hearing_location_attrs)
                  AppealRepository.update_location!(appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
                  vacols_hearing
                else
                  Hearing.create!(
                    appeal: appeal,
                    hearing_day_id: hearing_day.id,
                    hearing_location_attributes: hearing_location_attrs || {},
                    scheduled_time: hearing_datetime
                  )
                end

      hearing
    end

    def load_vacols_data(hearing)
      vacols_record = MetricsService.record("VACOLS: HearingRepository.load_vacols_data: #{hearing.vacols_id}",
                                            service: :vacols,
                                            name: "load_vacols_hearing_data") do
        VACOLS::CaseHearing.load_hearing(hearing.vacols_id)
      end

      if vacols_record
        set_vacols_values(hearing, vacols_record)
        true
      else
        fail Caseflow::Error::VacolsRecordNotFound, "Hearing record with vacols id #{hearing.vacols_id} not found."
      end
    rescue ActiveRecord::RecordNotFound
      false
    end

    def appeals_ready_for_hearing(vbms_id)
      AppealRepository.appeals_ready_for_hearing(vbms_id)
    end
    # :nocov:

    def set_vacols_values(hearing, vacols_record)
      hearing.assign_from_vacols(vacols_attributes(vacols_record))
      hearing
    end

    def hearings_for(case_hearings)
      uniq_case_hearings = case_hearings.uniq
      vacols_ids = uniq_case_hearings.map { |record| record[:hearing_pkseq] }.compact

      fetched_hearings = LegacyHearing.where(vacols_id: vacols_ids).includes(:appeal, :user, :hearing_views)
      fetched_hearings_hash = fetched_hearings.index_by { |hearing| hearing.vacols_id.to_i }

      uniq_case_hearings.map do |vacols_record|
        next empty_dockets(vacols_record) if master_record?(vacols_record)

        hearing = LegacyHearing
          .assign_or_create_from_vacols_record(vacols_record,
                                               legacy_hearing: fetched_hearings_hash[vacols_record.hearing_pkseq])
        set_vacols_values(hearing, vacols_record)
      end.flatten
    end

    private

    def worksheet_issues_for_appeals(appeal_ids)
      WorksheetIssue.issues_for_appeals(appeal_ids)
        .each_with_object({}) do |issue, hash|
        hash[issue.appeal_id] ||= []
        hash[issue.appeal_id] << issue
      end
    end

    def master_record?(record)
      record.master_record_type.present?
    end

    def empty_dockets(vacols_record)
      values = MasterRecordHelper.values_based_on_type(vacols_record)
      # Travel Board master records have a date range, so we create a master record for each day
      values[:dates].inject([]) do |result, date|
        result << Hearings::MasterRecord.new(scheduled_for: VacolsHelper.normalize_vacols_datetime(date),
                                             request_type: values[:request_type],
                                             master_record: true,
                                             regional_office_key: values[:ro])
        result
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def vacols_attributes(vacols_record)
      # use venue location on the hearing if it exists
      ro = vacols_record.hearing_venue || vacols_record.bfregoff
      date = HearingMapper.datetime_based_on_type(datetime: vacols_record.hearing_date,
                                                  regional_office_key: ro,
                                                  type: vacols_record.hearing_type)
      judge_id = if vacols_record.css_id.nil?
                   nil
                 else
                   User.find_by_css_id_or_create_with_default_station_id(vacols_record.css_id).id
                 end
      {
        vacols_record: vacols_record,
        appeal_vacols_id: vacols_record.folder_nr,
        venue_key: vacols_record.hearing_venue,
        disposition: VACOLS::CaseHearing::HEARING_DISPOSITIONS[vacols_record.hearing_disp.try(:to_sym)],
        representative_name: vacols_record.repname,
        representative: VACOLS::Case::REPRESENTATIVES[vacols_record.bfso][:full_name],
        aod: VACOLS::CaseHearing::HEARING_AODS[vacols_record.aod.try(:to_sym)],
        hold_open: vacols_record.holddays,
        transcript_requested: VACOLS::CaseHearing::BOOLEAN_MAP[vacols_record.tranreq.try(:to_sym)],
        transcript_sent_date: AppealRepository.normalize_vacols_date(vacols_record.transent),
        add_on: VACOLS::CaseHearing::BOOLEAN_MAP[vacols_record.addon.try(:to_sym)],
        notes: vacols_record.notes1,
        appellant_address_line_1: vacols_record.saddrst1,
        appellant_address_line_2: vacols_record.saddrst2,
        appellant_city: vacols_record.saddrcty,
        appellant_state: vacols_record.saddrstt,
        appellant_country: vacols_record.saddrcnty,
        appellant_zip: vacols_record.saddrzip,
        appeal_type: VACOLS::Case::TYPES[vacols_record.bfac],
        docket_number: vacols_record.tinum || "Missing Docket Number",
        veteran_first_name: vacols_record.snamef,
        veteran_middle_initial: vacols_record.snamemi,
        veteran_last_name: vacols_record.snamel,
        appellant_first_name: vacols_record.sspare2,
        appellant_middle_initial: vacols_record.sspare3,
        appellant_last_name: vacols_record.sspare1,
        room: vacols_record.room,
        request_type: vacols_record.hearing_type,
        scheduled_for: date,
        hearing_day_id: vacols_record.vdkey,
        master_record: false,
        bva_poc: vacols_record.vdbvapoc,
        judge_id: judge_id
      }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
