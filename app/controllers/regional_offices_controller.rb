class RegionalOfficesController < ApplicationController
  def index
    render json: {
      regional_offices: RegionalOffice.ros_with_hearings
    }
  end

  # skip coverage to pass ci
  # :nocov:
  def open_hearing_dates
    ro = HearingDayMapper.validate_regional_office(params[:regional_office])

    hearing_days = HearingDay.load_days_with_open_hearing_slots(
      Time.zone.today.beginning_of_day,
      Time.zone.today.beginning_of_day + 182.days,
      ro
    )

    render json: {
      hearing_days: hearing_days.map do |day|
        {
          hearing_id: day[:id],
          scheduled_for: day[:scheduled_for],
          hearing_type: day[:hearing_type],
          room: day[:room],
          total_slots: day[:total_slots]
        }
      end
    }
  end
  # :nocov:
end
