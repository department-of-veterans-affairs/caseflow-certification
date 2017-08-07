class VACOLS::CaseHearing < VACOLS::Record
  self.table_name = "vacols.hearsched"
  self.primary_key = "hearing_pkseq"

  has_one :staff, foreign_key: :sattyid, primary_key: :board_member
  has_one :brieff, foreign_key: :bfkey, primary_key: :folder_nr, class_name: "Case"

  HEARING_TYPES = {
    V: :video,
    T: :travel,
    C: :central_office
  }.freeze

  HEARING_DISPOSITIONS = {
    H: :held,
    C: :cancelled,
    P: :postponed,
    N: :no_show
  }.freeze

  HEARING_AODS = {
    G: :granted,
    Y: :filed,
    N: :none
  }.freeze

  BOOLEAN_MAP = {
    N: false,
    Y: true
  }.freeze

  TABLE_NAMES = {
    notes: :notes1,
    disposition: :hearing_disp,
    hold_open: :holddays,
    aod: :aod,
    transcript_requested: :tranreq
  }.freeze

  NOT_MASTER_RECORD = %(
    vdkey is NOT NULL
  ).freeze

  WITHOUT_DISPOSITION_OR_AFTER_DATE = %{
    hearing_date >= to_date(?, 'YYYY-MM-DD HH24:MI')
    -- Hearing is after a provided date (a recent hearing)

    OR hearing_disp IS NULL
    -- an older hearing still awaiting a disposition
  }.freeze

  after_update :update_hearing_action, if: :hearing_disp_changed?

  # :nocov:
  class << self
    def upcoming_for_judge(css_id)
      id = connection.quote(css_id)

      select_hearings
        .where("staff.sdomainid = #{id}")
        .where(WITHOUT_DISPOSITION_OR_AFTER_DATE,
               relative_vacols_date(date_diff).to_formatted_s(:oracle_date))
        .where(NOT_MASTER_RECORD)
    end

    def for_appeal(appeal_vacols_id)
      select_hearings.where(folder_nr: appeal_vacols_id)
    end

    def load_hearing(pkseq)
      select_hearings.find_by(hearing_pkseq: pkseq)
    end

    private

    def select_hearings
      # VACOLS overloads the HEARSCHED table with other types of hearings
      # that work differently. Filter those out.
      select("VACOLS.HEARING_VENUE(vdkey) as hearing_venue",
             "staff.stafkey as user_id",
             :hearing_disp,
             :hearing_pkseq,
             :hearing_date,
             :hearing_type,
             :notes1,
             :folder_nr,
             :vdkey,
             :aod,
             :holddays,
             :tranreq,
             :board_member,
             :mduser,
             :mdtime,
             :sattyid)
        .joins("left outer join vacols.staff on staff.sattyid = board_member")
        .where(hearing_type: HEARING_TYPES.keys)
    end
  end

  def update_hearing!(hearing_info)
    slogid = staff.try(:slogid)

    attrs = hearing_info.each_with_object({}) { |(k, v), result| result[TABLE_NAMES[k]] = v }
    MetricsService.record("VACOLS: update_hearing! #{hearing_pkseq}",
                          service: :vacols,
                          name: "update_hearing") do
      update(attrs.merge(mduser: slogid, mdtime: VacolsHelper.local_time_with_utc_timezone))
    end
  end

  private

  def update_hearing_action
    brieff.update(bfha: HearingMapper.bfha_vacols_code(self, brieff))
  end
  # :nocov:
end
