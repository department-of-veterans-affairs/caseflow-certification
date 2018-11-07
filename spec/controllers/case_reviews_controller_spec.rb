RSpec.describe CaseReviewsController, type: :controller do
  before do
    Fakes::Initializer.load!
    User.authenticate!(roles: ["System Admin"])
  end

  context "Ama appeal" do
    describe "POST case_reviews/:task_id/complete" do
      let(:judge) { create(:user, station_id: User::BOARD_STATION_ID) }
      let(:attorney) { create(:user, station_id: User::BOARD_STATION_ID) }

      let!(:judge_staff) { create(:staff, :judge_role, slogid: "CSF444", sdomainid: judge.css_id) }
      let!(:attorney_staff) { create(:staff, :attorney_role, slogid: "CSF555", sdomainid: attorney.css_id) }

      let(:request_issue1) { create(:request_issue, review_request: task.appeal) }
      let(:request_issue2) { create(:request_issue, review_request: task.appeal) }
      let(:decision_issue1) { create(:decision_issue, request_issue: request_issue1) }
      let(:decision_issue2) { create(:decision_issue, request_issue: request_issue2) }

      context "Attorney Case Review" do
        before do
          User.stub = attorney
        end

        let(:root_task) { create(:root_task) }
        let(:judge_task) { create(:ama_judge_task, assigned_to: judge, parent: root_task) }
        let(:task) { create(:ama_attorney_task, assigned_to: attorney, assigned_by: judge, parent: judge_task) }

        context "when all parameters are present to create Draft Decision" do
          let(:params) do
            {
              "type": "AttorneyCaseReview",
              "document_type": Constants::APPEAL_DECISION_TYPES["DRAFT_DECISION"],
              "reviewing_judge_id": judge.id,
              "work_product": "Decision",
              "document_id": "123456789.1234",
              "overtime": true,
              "note": "something",
              "issues": [{ "disposition": "allowed", "id": request_issue1.id },
                         { "disposition": "remanded", "id": request_issue2.id }]
            }
          end
          let!(:bva_dispatch_task_count_before) { BvaDispatchTask.count }

          it "should be successful" do
            post :complete, params: { task_id: task.id, tasks: params }
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)
            expect(response_body["task"]["document_id"]).to eq "123456789.1234"
            expect(response_body["task"]["overtime"]).to eq true
            expect(response_body["task"]["note"]).to eq "something"
            expect(response_body.keys).to include "issues"
            # TODO: uncomment when we use decision issues
            # expect(response_body["issues"]["decision_issues"].size).to eq 2
            expect(response_body["issues"]["request_issues"].size).to eq 2
            expect(request_issue1.reload.disposition).to eq "allowed"
            expect(request_issue2.reload.disposition).to eq "remanded"
            expect(task.reload.status).to eq "completed"
            expect(task.completed_at).to_not eq nil
            expect(task.parent.reload.status).to eq "assigned"
            expect(task.parent.action).to eq "review"

            expect(bva_dispatch_task_count_before).to eq(BvaDispatchTask.count)
          end
        end
      end

      context "Judge Case Review" do
        before do
          User.stub = judge
        end

        let(:root_task) { create(:root_task) }
        let(:task) { create(:ama_judge_task, assigned_to: judge, parent: root_task) }

        context "when all parameters are present to send to sign a decision" do
          let(:params) do
            {
              "type": "JudgeCaseReview",
              "location": "bva_dispatch",
              "attorney_id": attorney.id,
              "complexity": "easy",
              "quality": "meets_expectations",
              "comment": "do this",
              "factors_not_considered": %w[theory_contention relevant_records],
              "areas_for_improvement": ["process_violations"],
              "issues": [{ "disposition": "denied", "id": request_issue1.id },
                         { "disposition": "remanded", "id": request_issue2.id }]
            }
          end

          it "should be successful" do
            post :complete, params: { task_id: task.id, tasks: params }
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)
            location = response_body["task"]["location"]
            # We send a sampling of cases to quality review, either location is correct
            expect(location == "bva_dispatch" || location == "quality_review").to eq true
            expect(response_body["task"]["judge_id"]).to eq judge.id
            expect(response_body["task"]["attorney_id"]).to eq attorney.id
            expect(response_body["task"]["complexity"]).to eq "easy"
            expect(response_body["task"]["quality"]).to eq "meets_expectations"
            expect(response_body["task"]["comment"]).to eq "do this"
            expect(response_body["task"]["factors_not_considered"]).to eq %w[theory_contention relevant_records]
            expect(response_body["task"]["areas_for_improvement"]).to eq ["process_violations"]
            expect(response_body.keys).to include "issues"
            # TODO: uncomment when we use decision issues
            # expect(response_body["issues"]["decision_issues"].size).to eq 2
            expect(response_body["issues"]["request_issues"].size).to eq 2
            expect(request_issue1.reload.disposition).to eq "denied"
            expect(request_issue2.reload.disposition).to eq "remanded"
            expect(task.reload.status).to eq "completed"
            expect(task.completed_at).to_not eq nil

            quality_review_task = QualityReviewTask.find_by(parent_id: root_task.id)
            expect(quality_review_task.assigned_to).to eq(QualityReview.singleton)
          end

          context "When case is being QRed" do
            let(:qr_user) { create(:user) }
            let!(:quality_review_organization_task) do
              create(:qr_task, assigned_to: QualityReview.singleton, parent: root_task)
            end
            let!(:quality_review_task) do
              create(:qr_task, assigned_to: qr_user, parent: quality_review_organization_task)
            end
            let!(:task) { create(:ama_judge_task, assigned_to: judge, parent: quality_review_task) }

            it "should not create a new QR task" do
              expect(QualityReviewTask.count).to eq(2)
              expect(quality_review_task.status).to eq("on_hold")

              post :complete, params: { task_id: task.id, tasks: params }
              expect(response.status).to eq 200

              expect(QualityReviewTask.count).to eq(2)

              expect(quality_review_task.reload.status).to eq("assigned")
            end
          end
        end
      end
    end
  end

  context "Legacy appeal" do
    describe "POST case_reviews/:task_id/complete" do
      let(:judge) { create(:user, station_id: User::BOARD_STATION_ID) }
      let(:attorney) { create(:user, station_id: User::BOARD_STATION_ID) }

      let(:judge_staff) { create(:staff, :judge_role, slogid: "CSF444", sdomainid: judge.css_id) }
      let(:attorney_staff) { create(:staff, :attorney_role, slogid: "CSF555", sdomainid: attorney.css_id) }

      let(:task_id) { "#{vacols_case.bfkey}-#{vacols_case.decass.first.deadtim.strftime('%Y-%m-%d')}" }
      let(:vacols_issue_remanded) { create(:case_issue, :disposition_remanded, isskey: vacols_case.bfkey) }
      let(:vacols_issue_allowed) { create(:case_issue, :disposition_allowed, isskey: vacols_case.bfkey) }

      context "Attorney Case Review" do
        before do
          User.stub = attorney
        end

        let(:vacols_case) { create(:case, :assigned, bfcurloc: attorney_staff.slogid) }

        context "when all parameters are present to create OMO request" do
          let(:params) do
            {
              "type": "AttorneyCaseReview",
              "document_type": Constants::APPEAL_DECISION_TYPES["OMO_REQUEST"],
              "reviewing_judge_id": judge.id,
              "work_product": "OMO - IME",
              "document_id": "123456789.1234",
              "overtime": true,
              "note": "something"
            }
          end
          let!(:bva_dispatch_task_count_before) { BvaDispatchTask.count }

          it "should be successful" do
            post :complete, params: { task_id: task_id, tasks: params }
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)
            expect(response_body["task"]["document_id"]).to eq "123456789.1234"
            expect(response_body["task"]["overtime"]).to eq true
            expect(response_body["task"]["note"]).to eq "something"
            expect(bva_dispatch_task_count_before).to eq(BvaDispatchTask.count)
          end
        end

        context "when all parameters are present to create Draft Decision" do
          let(:params) do
            {
              "type": "AttorneyCaseReview",
              "document_type": Constants::APPEAL_DECISION_TYPES["DRAFT_DECISION"],
              "reviewing_judge_id": judge.id,
              "work_product": "Decision",
              "document_id": "123456789.1234",
              "overtime": true,
              "note": "something",
              "issues": [{ "disposition": "3", "id": vacols_issue_remanded.issseq },
                         { "disposition": "1", "id": vacols_issue_allowed.issseq }]
            }
          end
          let!(:bva_dispatch_task_count_before) { BvaDispatchTask.count }

          it "should be successful" do
            post :complete, params: { task_id: task_id, tasks: params }
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)
            expect(response_body["task"]["document_id"]).to eq "123456789.1234"
            expect(response_body["task"]["overtime"]).to eq true
            expect(response_body["task"]["note"]).to eq "something"
            expect(response_body.keys).to include "issues"
            expect(bva_dispatch_task_count_before).to eq(BvaDispatchTask.count)
          end
        end

        context "when not all parameters are present" do
          let(:params) do
            {
              "type": "AttorneyCaseReview",
              "document_type": Constants::APPEAL_DECISION_TYPES["OMO_REQUEST"],
              "work_product": "OMO - IME",
              "document_id": "123456789.1234",
              "overtime": true,
              "note": "something"
            }
          end

          it "should not be successful" do
            post :complete, params: { task_id: task_id, tasks: params }
            expect(response.status).to eq 400
            response_body = JSON.parse(response.body)
            expect(response_body["errors"].first["title"]).to eq "Record is invalid"
            expect(response_body["errors"].first["detail"]).to eq "Reviewing judge can't be blank"
          end
        end
      end

      context "Judge Case Review" do
        before do
          User.stub = judge
          expect(QueueRepository).to receive(:sign_decision_or_create_omo!).and_return(true)
          # Do not select the case for quaility review
          allow_any_instance_of(JudgeCaseReview).to receive(:rand).and_return(probability + probability)
        end

        let(:probability) { JudgeCaseReview::QUALITY_REVIEW_SELECTION_PROBABILITY }
        let(:vacols_case) { create(:case, :assigned, bfcurloc: judge_staff.slogid) }

        context "when all parameters are present to send to omo office" do
          let(:params) do
            {
              "type": "JudgeCaseReview",
              "location": "omo_office",
              "attorney_id": attorney.id
            }
          end

          it "should be successful" do
            post :complete, params: { task_id: task_id, tasks: params }
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)
            expect(response_body["task"]["location"]).to eq "omo_office"
          end
        end

        context "when all parameters are present to send to sign a decision" do
          let(:params) do
            {
              "type": "JudgeCaseReview",
              "location": "bva_dispatch",
              "attorney_id": attorney.id,
              "complexity": "easy",
              "quality": "meets_expectations",
              "comment": "do this",
              "factors_not_considered": %w[theory_contention relevant_records],
              "areas_for_improvement": ["process_violations"],
              "issues": [{ "disposition": "1", "id": vacols_issue_remanded.issseq },
                         { "disposition": "3", "id": vacols_issue_allowed.issseq }]
            }
          end

          it "should be successful" do
            post :complete, params: { task_id: task_id, tasks: params }
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)
            expect(response_body["task"]["location"]).to eq "bva_dispatch"
            expect(response_body["task"]["judge_id"]).to eq judge.id
            expect(response_body["task"]["attorney_id"]).to eq attorney.id
            expect(response_body["task"]["complexity"]).to eq "easy"
            expect(response_body["task"]["quality"]).to eq "meets_expectations"
            expect(response_body["task"]["comment"]).to eq "do this"
            expect(response_body.keys).to include "issues"
            expect(response_body["issues"].select do |i|
              i["vacols_sequence_id"] == vacols_issue_remanded.issseq
            end.first["disposition"]).to eq "allowed"
            expect(response_body["issues"].select do |i|
              i["vacols_sequence_id"] == vacols_issue_allowed.issseq
            end.first["disposition"]).to eq "remanded"
          end
        end
      end
    end
  end
end
