# Class to coordinate interactions between controller
# and repository class. Eventually may persist data to
# Caseflow DB. For now all schedule data is sent to the
# VACOLS DB (Aug 2018 implementation).
class HearingDay < ApplicationRecord
  HEARING_TYPES = {
    video: "V",
    travel: "T",
    central: "C"
  }.freeze

  CASEFLOW_SCHEDULE_DATE = Date.new(2019, 3, 31).freeze

  class << self
    def create_hearing_day(hearing_hash)
      if Date.parse(hearing_hash[:hearing_date]) > CASEFLOW_SCHEDULE_DATE
        create(hearing_hash).to_hash
      else
        HearingDayRepository.create_vacols_hearing!(hearing_hash)
      end
    end

    def update_hearing_day(hearing, hearing_hash)
      if hearing.class.name === "HearingDay"
        hearing.update(hearing_hash).to_hash
      else
        HearingDayRepository.update_vacols_hearing!(hearing, hearing_hash)
      end
    end

    def create_schedule(scheduled_hearings)
      scheduled_hearings.each do |hearing_hash|
        HearingDay.create_hearing_day(hearing_hash)
      end
    end

    def update_schedule(updated_hearings)
      updated_hearings.each do |hearing_hash|
        hearing_to_update = HearingDay.find_hearing_day(hearing_hash[:hearing_type], hearing_hash[:hearing_key])
        hearing_hash.delete(:hearing_key)
        HearingDay.update_hearing_day(hearing_to_update, hearing_hash)
      end
    end

    def load_days(start_date, end_date, regional_office = nil)
      if regional_office.nil?
        cf_video_and_co = where("hearing_date between ? and ?", start_date, end_date).each_with_object([]) do |hearing_day, result|
          result << hearing_day.to_hash
        end
        video_and_co, travel_board = HearingDayRepository.load_days_for_range(start_date, end_date)
      else
        cf_video_and_co = where("regional_office = ? and hearing_date between ? and ?",
                                regional_office, start_date, end_date).each_with_object([]) do |hearing_day, result|
          result << hearing_day.to_hash
        end
        video_and_co, travel_board =
            HearingDayRepository.load_days_for_regional_office(regional_office, start_date, end_date)
      end
      total_video_and_co = cf_video_and_co + video_and_co
      [total_video_and_co, travel_board]
    end

    def find_hearing_day(hearing_type, hearing_key)
      hearing_day = find(hearing_key)
      rescue ActiveRecord::RecordNotFound
        hearing_day = HearingDayRepository.find_hearing_day(hearing_type, hearing_key)
      hearing_day
    end
  end

  def to_hash
    as_json.each_with_object({}) do |(k, v), result|
      if k == "room_info"
        result[k.to_sym] = HearingDayMapper.label_for_room(v)
      elsif k == "regional_office" && !v.nil?
        ro = v[6, v.length]
        result[k.to_sym] = HearingDayMapper.city_for_regional_office(ro)
      elsif k == "hearing_type"
        result[k.to_sym] = HearingDayMapper.label_for_type(v)
      else
        result[k.to_sym] = v
      end
    end
  end
end
