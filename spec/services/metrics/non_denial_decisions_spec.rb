# frozen_string_literal: true

describe Metrics::NonDenialDecisions, :postgres do
  let(:user) { create(:user) }
  let(:start_date) { Time.zone.now - 45.days }
  let(:end_date) { Time.zone.now - 15.days }
  let(:date_range) { Metrics::DateRange.new(start_date, end_date) }
  let(:outcode_params) do
    {
      citation_number: "12312312",
      decision_date: Date.new(1989, 11, 9).to_s,
      file: "longfilenamehere",
      redacted_document_location: "C://Windows/User/BVASWIFTT/Documents/NewDecision.docx"
    }
  end
  let(:number_of_decisions_in_range) { 25 }
  let(:number_of_end_products_created_in_7_days) { 10 }
  before do
    bva_dispatcher = create(:user)
    BvaDispatch.singleton.add_user(bva_dispatcher)
    decision_issues = (0...number_of_decisions_in_range).map do
      appeal = create(:appeal, :outcoded, decision_documents: [create(:decision_document)])
      BvaDispatchTask.create_from_root_task(appeal.root_task).update(status: Constants.TASK_STATUSES.completed)
      create(:decision_issue, decision_review: appeal)
    end

    BvaDispatchTask.where(status: Constants.TASK_STATUSES.completed).update_all(closed_at: Time.zone.now - 30.days)
    decision_issues.sample(number_of_end_products_created_in_7_days).each do |decision|
      create(:end_product_establishment, source: decision.decision_review.decision_documents.first)
    end
  end

  subject { Metrics::NonDenialDecisions.new(date_range).call }

  it do
    expect(subject).to eq(number_of_end_products_created_in_7_days / number_of_decisions_in_range.to_f)
  end

  context "when start date is within 7 days" do
    let(:start_date) { Time.zone.now - 4.days }

    it do
      expect { subject }.to raise_error(Metrics::DateRange::DateRangeError)
    end
  end
end
