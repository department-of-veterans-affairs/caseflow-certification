# frozen_string_literal: true

describe DocketCoordinator do
  before do
    FeatureToggle.enable!(:test_facols)
    FeatureToggle.enable!(:ama_auto_case_distribution)
    Timecop.freeze(Time.utc(2020, 4, 1, 12, 0, 0))

    4.times do
      team = JudgeTeam.create_for_judge(FactoryBot.create(:user))
      FactoryBot.create_list(:user, 5).each do |attorney|
        OrganizationsUser.add_user_to_organization(attorney, team)
      end
    end

    allow_any_instance_of(DirectReviewDocket)
      .to receive(:nonpriority_receipts_per_year)
      .and_return(nonpriority_receipts_per_year)

    allow(Appeal)
      .to receive(:nonpriority_decisions_per_year)
      .and_return(nonpriority_decisions_per_year)
  end

  after do
    FeatureToggle.disable!(:test_facols)
    FeatureToggle.disable!(:ama_auto_case_distribution)
  end

  let(:nonpriority_receipts_per_year) { 100 }
  let(:nonpriority_decisions_per_year) { 1000 }

  let(:docket_coordinator) { DocketCoordinator.new }

  let(:priority_case_count) { 10 }

  let!(:priority_cases) do
    (0...priority_case_count).map do |i|
      create(:case,
             :aod,
             bfd19: 2.years.ago,
             bfac: "1",
             bfmpro: "ACT",
             bfcurloc: "81",
             bfdloout: i.days.ago,
             folder: build(:folder, tinum: "1801#{format('%03d', i)}", titrnum: "123456789S"))
    end
  end

  let(:nonpriority_legacy_count) { 10 }

  let!(:nonpriority_legacy_cases) do
    (0...nonpriority_legacy_count).map do |i|
      create(:case,
             bfd19: 3.years.ago,
             bfac: "1",
             bfmpro: "ACT",
             bfcurloc: "81",
             bfdloout: i.days.ago,
             folder: build(:folder, tinum: "1701#{format('%03d', i)}", titrnum: "123456789S"))
    end
  end

  let(:due_direct_review_count) { 10 }

  let!(:due_direct_review_cases) do
    (0...due_direct_review_count).map do
      create(:appeal,
             :with_tasks,
             docket_type: "direct_review",
             receipt_date: 11.months.ago,
             target_decision_date: 1.month.from_now)
    end
  end

  let!(:other_direct_review_cases) do
    (0...10).map do
      create(:appeal,
             :with_tasks,
             docket_type: "direct_review",
             receipt_date: 61.days.ago,
             target_decision_date: 304.days.from_now)
    end
  end

  let(:other_docket_count) { 5 }

  let!(:evidence_submission_cases) do
    (0...other_docket_count).map do
      create(:appeal, :with_tasks, docket_type: "evidence_submission")
    end
  end

  let!(:hearing_cases) do
    (0...other_docket_count).map do
      create(:appeal, :with_tasks, docket_type: "hearing")
    end
  end

  context "when there are due direct reviews" do
    it "uses the number of due direct reviews as a proportion of the docket margin net of priority" do
      expect(docket_coordinator.docket_proportions).to eq(
        legacy: 0.4,
        direct_review: 0.2,
        evidence_submission: 0.2,
        hearing: 0.2
      )
      expect(docket_coordinator.pacesetting_direct_review_proportion).to eq(0.1)
      expect(docket_coordinator.interpolated_minimum_direct_review_proportion).to eq(0.067)
      expect(docket_coordinator.target_number_of_ama_hearings(2.years)).to eq(400)
    end

    context "when the direct review proportion would exceed 80%" do
      let(:due_direct_review_count) { 170 }

      it "caps the percentage at 80%" do
        expect(docket_coordinator.docket_proportions).to include(
          legacy: 0.1,
          direct_review: 0.8
        )
      end
    end

    context "when the legacy proportion would dip below 10%" do
      let(:priority_case_count) { 0 }
      let(:due_direct_review_count) { 60 }
      let(:nonpriority_legacy_count) { 12 }
      let(:other_docket_count) { 12 }

      it "ensures a minimum of 10%" do
        expect(docket_coordinator.docket_proportions).to include(
          legacy: 0.1,
          direct_review: 0.8
        )
      end

      context "unless there aren't that many cases" do
        let(:nonpriority_legacy_count) { 3 }

        it "uses the maximum number possible" do
          expect(docket_coordinator.docket_proportions).to include(
            legacy: 0.05,
            direct_review: 0.8
          )
        end
      end
    end
  end

  context "when there are no due direct reviews" do
    let(:due_direct_review_count) { 0 }
    let(:nonpriority_receipts_per_year) { 1000 }
    let(:nonpriority_decisions_per_year) { 1340 }
    let(:nonpriority_legacy_count) { 80 }

    it "uses the pacesetting direct review proportion" do
      expect(docket_coordinator.docket_proportions).to include(
        legacy: 0.8,
        evidence_submission: 0.05,
        hearing: 0.05
      )
      expect(docket_coordinator.interpolated_minimum_direct_review_proportion).to be_within(0.001).of(0.1)
    end
  end
end
