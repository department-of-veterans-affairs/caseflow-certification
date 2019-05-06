# frozen_string_literal: true

class HearingTimeService
  attr_accessor :hearing

  def self.handle_time_params(hearing_to_update, hearing_params:)
    # takes :hour/:minute params from controller and converts them to either vacols or caseflow
    # update params
    hour = hearing_params.delete(:hour)
    min = hearing_params.delete(:min)

    return hearing_params if hour.nil? || min.nil?

    hearing_params.tap do |params|
      if hearing_to_update.is_a?(LegacyHearing)
        params[:scheduled_for] = vacols_formatted_scheduled_for_datetime(
          scheduled_for: params[:scheduled_for] || hearing_to_update.scheduled_for,
          hour: hour,
          min: min
        )
      else
        params[:scheduled_for_time] = "#{hour}:#{min}"
      end
    end
  end

  def self.vacols_formatted_scheduled_for_datetime(scheduled_for:, hour:, min:)
    hearing_datetime = scheduled_for.to_datetime.change(
      hour: hour,
      min: min
    )

    VacolsHelper.format_datetime_with_utc_timezone(hearing_datetime)
  end

  def initialize(hearing:)
    @hearing = hearing
  end

  def to_s
    if hearing.is_a?(LegacyHearing)
      time_string_from_vacols_hearing_date
    else
      hearing.scheduled_for_time || time_string_from_scheduled_time
    end
  end

  def time_hash
    hour_min = time_string.split(":")
    {
      hour: hour_min[0],
      min: hour_min[1]
    }
  end

  def date
    hearing.scheduled_for.to_date
  end

  def central_office_time
    hearing_time = DateTime.now.change(
      hour: time_hash[:hour],
      min: time_hash[:min],
      offset: Time.now.in_time_zone('America/New_York').strftime('%z')
    )

    co_time = hearing_time.in_time_zone('America/New_York')

    "#{co_time.hour}:#{co_time.min}"
  end

  def time_string_from_scheduled_time
    "#{hearing.scheduled_time.hour}:#{hearing.scheduled_time.min}"
  end

  def time_string_from_vacols_hearing_date
    "#{hearing.scheduled_for.hour}:#{hearing.scheduled_for.min}"
  end
end
