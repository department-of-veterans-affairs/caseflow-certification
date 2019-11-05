# frozen_string_literal: true

class HearingDayRoomService
  def initialize(request_type:, assign_room: nil, scheduled_for:, room:)
    @request_type = request_type
    # if assign_room is nil, then this was invoked by judge algorithm
    @assign_room = assign_room.nil? ? false : ActiveRecord::Type::Boolean.new.deserialize(assign_room)
    @scheduled_for = scheduled_for
    @room = room
  end

  def rooms_are_available?
    return true if !assign_room

    available_room.present?
  end

  def available_room
    @available_room ||= if request_type == HearingDay::REQUEST_TYPES[:central]
                          first_available_central_room
                        else
                          first_available_video_room
                        end
  end

  def first_available_central_room
    room_count = hearing_count_by_room["2"] || 0
    "2" if room_count == 0
  end

  def first_available_video_room
    (1..HearingRooms::ROOMS.size).detect do |room_number|
      room_count = hearing_count_by_room[room_number.to_s] || 0
      room_number != 2 && room_count == 0
    end&.to_s
  end

  def hearing_count_by_room
    HearingDay.where(scheduled_for: scheduled_for, request_type: request_type)
      .group(:room).count
  end

  private

  attr_reader :room, :assign_room, :scheduled_for, :request_type
end
