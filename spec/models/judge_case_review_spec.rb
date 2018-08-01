describe JudgeCaseReview do
  let(:judge) { User.create(css_id: "CFS123", station_id: User::BOARD_STATION_ID) }
  let(:attorney) { User.create(css_id: "CFS456", station_id: "317") }
  let!(:decass) { create(:decass, deadtim: "2013-12-06".to_date, defolder: "123456", deprod: work_product) }
  let!(:vacols_case) { create(:case, bfkey: "123456", bfmemid: "AA", bfboard: "BB") }
  let!(:vacols_issue1) { create(:case_issue, isskey: "123456") }
  let!(:vacols_issue2) { create(:case_issue, isskey: "123456") }
  let!(:judge_staff) { create(:staff, :judge_role, slogid: "CFS456", sdomainid: judge.css_id) }

  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  context ".create" do
    subject { JudgeCaseReview.complete(params) }

    context "when all parameters are present to sign a decision and VACOLS update is successful" do
      before do
        RequestStore.store[:current_user] = judge
        FeatureToggle.enable!(:test_facols)
        allow(UserRepository).to receive(:can_access_task?).and_return(true)
      end

      after do
        FeatureToggle.disable!(:test_facols)
      end

      context "when selected for quality review" do
        let(:params) do
          {
            location: "bva_dispatch",
            judge: judge,
            task_id: "123456-2013-12-06",
            attorney: attorney,
            complexity: "hard",
            quality: "does_not_meet_expectations",
            comment: "do this",
            factors_not_considered: %w[theory_contention relevant_records],
            areas_for_improvement: ["process_violations"],
            issues: issues
          }
        end
        let(:issues) do
          [
            { disposition: "5", vacols_sequence_id: vacols_issue1.issseq, readjudication: true },
            { disposition: "3", vacols_sequence_id: vacols_issue2.issseq,
              remand_reasons: [{ code: "AB", after_certification: true }] }
          ]
        end
        let(:work_product) { "DEC" }

        it "should create judge case review and change the location to quality review" do
          allow_any_instance_of(JudgeCaseReview).to receive(:rand).and_return(0.02)
          expect(subject.valid?).to eq true
          expect(subject.location).to eq "quality_review"
          expect(subject.complexity).to eq "hard"
          expect(subject.quality).to eq "does_not_meet_expectations"
          expect(subject.comment).to eq "do this"
          expect(subject.factors_not_considered).to eq %w[theory_contention relevant_records]
          expect(subject.areas_for_improvement).to eq ["process_violations"]
          expect(subject.judge).to eq judge
          expect(subject.attorney).to eq attorney
          expect(decass.reload.demdusr).to eq "CFS456"
          expect(decass.defdiff).to eq "3"
          expect(decass.deoq).to eq "1"
          expect(decass.deqr2).to eq "Y"
          expect(decass.deqr6).to eq "Y"
          expect(decass.deqr9).to eq "Y"
          expect(decass.deqr1).to eq nil
          expect(decass.deqr3).to eq nil
          expect(decass.deqr4).to eq nil
          expect(vacols_case.reload.bfcurloc).to eq "48"

          vacols_issues = VACOLS::CaseIssue.where(isskey: "123456")
          # 1 vacated, 1 remanded and 1 blank issue created because of vacated disposition
          expect(vacols_issues.size).to eq 3

          expect(vacols_issues.first.issdc).to eq "5"
          expect(vacols_issues.first.issseq).to eq vacols_issue1.issseq
          expect(vacols_issues.first.issmduser).to eq "CFS456"

          expect(vacols_issues.second.issdc).to eq "3"
          expect(vacols_issues.second.issseq).to eq vacols_issue2.issseq
          expect(vacols_issues.second.issmduser).to eq "CFS456"

          expect(vacols_issues.third.issdc).to eq nil
          expect(vacols_issues.third.issseq).to eq(vacols_issue2.issseq + 1)
          expect(vacols_issues.third.issaduser).to eq "CFS456"

          remand_reasons = VACOLS::RemandReason.where(rmdkey: "123456", rmdissseq: vacols_issue2.issseq)
          expect(remand_reasons.size).to eq 1
          expect(remand_reasons.first.rmdissseq).to eq vacols_issue2.issseq
          expect(remand_reasons.first.rmdmdusr).to eq "CFS456"

          quality_review_record = VACOLS::DecisionQualityReview.find_by(qrfolder: vacols_case.bfkey)
          expect(quality_review_record.qrsmem).to eq "AA"
          expect(quality_review_record.qrteam).to eq "BB"
          expect(quality_review_record.qrseldate).to eq VacolsHelper.local_date_with_utc_timezone
          expect(quality_review_record.qryymm).to eq "1501"
        end
      end

      context "when bva dispatch" do
        let(:params) do
          {
            location: "bva_dispatch",
            judge: judge,
            task_id: "123456-2013-12-06",
            attorney: attorney,
            complexity: "hard",
            quality: "does_not_meet_expectations",
            comment: "do this",
            factors_not_considered: %w[theory_contention relevant_records],
            areas_for_improvement: ["process_violations"],
            issues: issues
          }
        end
        let(:issues) do
          [
            { disposition: "5", vacols_sequence_id: vacols_issue1.issseq, readjudication: true },
            { disposition: "3", vacols_sequence_id: vacols_issue2.issseq,
              remand_reasons: [{ code: "AB", after_certification: true }] }
          ]
        end
        let(:work_product) { "DEC" }

        it "should create Judge Case Review" do
          expect(subject.valid?).to eq true
          expect(subject.location).to eq "bva_dispatch"
          expect(subject.complexity).to eq "hard"
          expect(subject.quality).to eq "does_not_meet_expectations"
          expect(subject.comment).to eq "do this"
          expect(subject.factors_not_considered).to eq %w[theory_contention relevant_records]
          expect(subject.areas_for_improvement).to eq ["process_violations"]
          expect(subject.judge).to eq judge
          expect(subject.attorney).to eq attorney
          expect(decass.reload.demdusr).to eq "CFS456"
          expect(decass.defdiff).to eq "3"
          expect(decass.deoq).to eq "1"
          expect(decass.deqr2).to eq "Y"
          expect(decass.deqr6).to eq "Y"
          expect(decass.deqr9).to eq "Y"
          expect(decass.deqr1).to eq nil
          expect(decass.deqr3).to eq nil
          expect(decass.deqr4).to eq nil
          expect(vacols_case.reload.bfcurloc).to eq "4E"

          vacols_issues = VACOLS::CaseIssue.where(isskey: "123456")
          # 1 vacated, 1 remanded and 1 blank issue created because of vacated disposition
          expect(vacols_issues.size).to eq 3

          expect(vacols_issues.first.issdc).to eq "5"
          expect(vacols_issues.first.issseq).to eq vacols_issue1.issseq
          expect(vacols_issues.first.issmduser).to eq "CFS456"

          expect(vacols_issues.second.issdc).to eq "3"
          expect(vacols_issues.second.issseq).to eq vacols_issue2.issseq
          expect(vacols_issues.second.issmduser).to eq "CFS456"

          expect(vacols_issues.third.issdc).to eq nil
          expect(vacols_issues.third.issseq).to eq(vacols_issue2.issseq + 1)
          expect(vacols_issues.third.issaduser).to eq "CFS456"

          remand_reasons = VACOLS::RemandReason.where(rmdkey: "123456", rmdissseq: vacols_issue2.issseq)
          expect(remand_reasons.size).to eq 1
          expect(remand_reasons.first.rmdissseq).to eq vacols_issue2.issseq
          expect(remand_reasons.first.rmdmdusr).to eq "CFS456"

          expect(VACOLS::DecisionQualityReview.find_by(qrfolder: vacols_case.bfkey)).to eq nil
        end
      end

      context "when omo office" do
        let(:params) do
          {
            location: "omo_office",
            judge: judge,
            task_id: "123456-2013-12-06",
            attorney: attorney
          }
        end
        let(:work_product) { "IME" }

        it "should create Judge Case Review" do
          allow_any_instance_of(JudgeCaseReview).to receive(:rand).and_return(0.02)
          expect(subject.valid?).to eq true
          expect(subject.location).to eq "omo_office"
          expect(subject.judge).to eq judge
          expect(subject.attorney).to eq attorney
          expect(vacols_case.reload.bfcurloc).to eq "20"

          expect(VACOLS::DecisionQualityReview.find_by(qrfolder: vacols_case.bfkey)).to eq nil
        end
      end
    end
  end
end
