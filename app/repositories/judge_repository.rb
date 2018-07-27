class JudgeRepository
  def self.find_all_judges
    records = VACOLS::Staff.where(svlj: %w[J A], sactive: "A")
    records.select(&:sdomainid).map do |record|
      User.find_or_create_by(css_id: record.sdomainid, station_id: User::BOARD_STATION_ID)
    end
  end

  def self.find_all_judges_with_name_and_id
    records = VACOLS::Staff.where(svlj: %w[J A], sactive: "A")
    # Our user model only contains a full name field, but for certain applications
    # (like the IDT), we need the separate name fields from VACOLS.
    records.map do |record|
      { first_name: record.snamef,
        middle_name: record.snamemi,
        last_name: record.snamel,
        vacols_attorney_id: record.sattyid }
    end
  end
end
