class Hearing < ActiveRecord::Base
  belongs_to :appeal
  belongs_to :user

  attr_accessor :date, :type, :hearing_venue_key, :vacols_record

  def attributes
    {
      date: date,
      type: type,
      venue: venue
    }
  end

  # If venue exists via the vdkey, we use that, otherwise
  # fall back to the appeal's regional_office_key
  def venue_key
    hearing_venue_key || appeal.regional_office_key
  end

  def venue
    VACOLS::RegionalOffice::CITIES[venue_key]
  end

  def self.load_from_vacols(vacols_hearing, vacols_user_id)
    find_or_create_by(vacols_id: vacols_hearing.hearing_pkseq).tap do |hearing|
      hearing.attributes = {
        vacols_record: vacols_hearing,
        hearing_venue_key: normalize_vacols_hearing_venue_key(vacols_hearing.hearing_venue),
        date: AppealRepository.normalize_vacols_date(vacols_hearing.hearing_date),
        appeal: Appeal.find_or_create_by(vacols_id: vacols_hearing.folder_nr),
        user: User.find_by_vacols_id(vacols_user_id),
        type: VACOLS::CaseHearing::HEARING_TYPES[vacols_hearing.hearing_type.to_sym]
      }
    end
  end

  private

  def self.normalize_vacols_hearing_venue_key(hearing_venue)
    hearing_venue.tr("SO", "RO") if hearing_venue
  end
end
