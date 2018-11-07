class HearingsController < ApplicationController
  before_action :verify_access, except: [:show_print, :show, :update]
  before_action :check_hearing_prep_out_of_service
  before_action :verify_access_to_reader_or_hearings, only: [:show_print, :show]
  before_action :verify_access_to_hearing_prep_or_schedule, only: [:update]

  def update
    if params["hearing"]["date"]
      new_hearing_params = update_params
      parent_record = to_hash(HearingDay.find_hearing_day(nil, params["hearing"]["date"]))
      parent_record[:folder_nr] = hearing.appeal.vacols_id
      parent_record.delete(:judge_last_name)
      parent_record.delete(:judge_middle_name)
      parent_record.delete(:judge_first_name)
      parent_record.delete(:judge_name)
      HearingRepository.create_vacols_child_hearing(parent_record)
    elsif params["hearing"]["time"]
      new_hearing_params = time_update_params(hearing.date)
    else
      new_hearing_params = update_params
    end

    hearing.update(new_hearing_params)
    render json: hearing.to_hash(current_user.id)
  end

  def logo_name
    "Hearing Prep"
  end

  def logo_path
    hearings_dockets_path
  end

  private

  def to_hash(hearing)
    hearing.as_json.each_with_object({}) do |(k, v), result|
      result[k.to_sym] = v
    end
  end

  def check_hearing_prep_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("hearing_prep_out_of_service")
  end

  def hearing
    @hearing ||= Hearing.find(hearing_id)
  end

  def hearing_id
    params[:id]
  end

  def verify_access
    verify_authorized_roles("Hearing Prep")
  end

  def verify_access_to_reader_or_hearings
    verify_authorized_roles("Reader", "Hearing Prep")
  end

  def verify_access_to_hearing_prep_or_schedule
    verify_authorized_roles("Hearing Prep", "Edit HearSched", "Build HearSched")
  end

  def set_application
    RequestStore.store[:application] = "hearings"
  end

  def time_update_params(original_date)
    params.require("hearing").permit(:notes,
                                     :disposition,
                                     :hold_open,
                                     :aod,
                                     :transcript_requested,
                                     :add_on,
                                     :prepped).merge(date: original_date.change(hour: 14, min: 30, sec: 0))
  end

  def update_params
    params.require("hearing").permit(:notes,
                                     :disposition,
                                     :hold_open,
                                     :aod,
                                     :transcript_requested,
                                     :add_on,
                                     :prepped)
  end
end
