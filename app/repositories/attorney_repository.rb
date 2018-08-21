class AttorneyRepository
  def self.find_all_attorneys
    records = VACOLS::Staff.where(sactive: "A").where.not(sattyid: nil)
    records.select(&:sdomainid).map do |record|
      User.find_or_create_by(css_id: record.sdomainid, station_id: User::BOARD_STATION_ID)
    end
  end

  def self.find_by_attorney_id(id)
    VACOLS::Staff.find_by(sattyid: id)
  end
end
