class Fakes::CaseAssignmentRepository < CaseAssignmentRepository
  # rubocop:disable MethodLength
  def self.load_from_vacols(_user_id)
    [
      Appeal.create_appeal_without_lazy_load(vacols_id: "reader_id1",
                                             date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
                                             date_received: "2013-05-31 00:00:00 UTC".to_datetime,
                                             signed_date: nil,
                                             vbms_id: "1234",
                                             veteran_first_name: "Simple",
                                             veteran_middle_initial: "A",
                                             veteran_last_name: "Case"),
      Appeal.create_appeal_without_lazy_load(vacols_id: "reader_id2",
                                             date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
                                             date_received: nil,
                                             signed_date: nil,
                                             vbms_id: "5",
                                             veteran_first_name: "Large",
                                             veteran_middle_initial: "B",
                                             veteran_last_name: "Case"),
      Appeal.create_appeal_without_lazy_load(vacols_id: "reader_id3",
                                             date_assigned: "2013-04-23 00:00:00 UTC".to_datetime,
                                             date_received: "2013-04-29 00:00:00 UTC".to_datetime,
                                             signed_date: nil,
                                             vbms_id: "6",
                                             veteran_first_name: "Redacted",
                                             veteran_middle_initial: "C",
                                             veteran_last_name: "Case")
    ]
  end
  # rubocop:enable MethodLength
end
