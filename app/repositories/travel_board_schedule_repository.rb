# frozen_string_literal: true

class TravelBoardScheduleRepository
  class << self
    def load_travel_board_days_for_range(start_date, end_date)
      VACOLS::TravelBoardSchedule.load_days_for_range(start_date, end_date)
    end
  end
end
