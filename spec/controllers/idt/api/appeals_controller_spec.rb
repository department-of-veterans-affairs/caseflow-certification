RSpec.describe Idt::Api::V1::AppealsController, type: :controller, focus: true do
  before do
    User.authenticate!(user: user)

    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  describe "GET /idt/api/v1/appeals" do
    let(:user) { create(:user, css_id: "TEST_ID", full_name: "George Michael") }

    let(:token) do
      key, token = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      token
    end

    context "when request header does not contain token" do
      it "response should error" do
        get :list
        expect(response.status).to eq 400
      end
    end

    context "when request header contains invalid token" do
      before { request.headers["TOKEN"] = "3289fn893rnqi8hf3nf" }

      it "responds with an error" do
        get :list
        expect(response.status).to eq 403
      end
    end

    context "when request header contains inactive token" do
      before do
        _key, t = Idt::Token.generate_one_time_key_and_proposed_token
        request.headers["TOKEN"] = t
      end

      it "responds with an error" do
        get :list
        expect(response.status).to eq 403
      end
    end

    context "when request header contains valid token" do
      context "and user is not an attorney" do
        before do
          create(:user, css_id: "ANOTHER_TEST_ID")
          key, t = Idt::Token.generate_one_time_key_and_proposed_token
          Idt::Token.activate_proposed_token(key, "ANOTHER_TEST_ID")
          request.headers["TOKEN"] = t
        end

        it "returns an error", skip: "fails intermittently, debugging in future PR" do
          get :list
          expect(response.status).to eq 403
        end
      end

      context "and user is an attorney" do
        let(:role) { :attorney_role }

        before do
          request.headers["TOKEN"] = token
        end

        let!(:appeals) do
          [
            create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user)),
            create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user))
          ]
        end

        let(:veteran1) { create(:veteran) }
        let(:veteran2) { create(:veteran) }

        let!(:ama_appeals) do
          [
            create(:appeal, veteran: veteran1, number_of_claimants: 2),
            create(:appeal, veteran: veteran2, number_of_claimants: 1)
          ]
        end

        let!(:tasks) do
          [
            create(:ama_attorney_task, assigned_to: user, appeal: ama_appeals.first),
            create(:ama_attorney_task, assigned_to: user, appeal: ama_appeals.second)
          ]
        end

        context "with AMA appeals" do
          before do
            FeatureToggle.enable!(:idt_ama_appeals)
          end

          after do
            FeatureToggle.disable!(:idt_ama_appeals)
          end

          it "returns a list of assigned appeals" do
            get :list
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["data"]
            ama_appeals = response_body.select { |appeal| appeal["type"] == "appeals" }
            expect(ama_appeals.size).to eq 2
            expect(ama_appeals.first["id"]).to eq tasks.first.appeal.uuid
            expect(ama_appeals.first["attributes"]["docket_number"]).to eq tasks.first.appeal.docket_number
            expect(ama_appeals.first["attributes"]["veteran_first_name"]).to eq veteran1.name.first_name

            expect(ama_appeals.second["id"]).to eq tasks.second.appeal.uuid
            expect(ama_appeals.second["attributes"]["docket_number"]).to eq tasks.second.appeal.docket_number
            expect(ama_appeals.second["attributes"]["veteran_first_name"]).to eq veteran2.name.first_name
          end

          it "returns appeals associated with a file number" do
            headers = { "FILENUMBER" => tasks.first.appeal.veteran_file_number }
            request.headers.merge! headers
            get :list
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["data"]
            ama_appeals = response_body.select { |appeal| appeal["type"] == "appeals" }
            expect(ama_appeals.size).to eq 1
            expect(ama_appeals.first["attributes"]["docket_number"]).to eq tasks.first.appeal.docket_number
            expect(ama_appeals.first["attributes"]["veteran_first_name"]).to eq veteran1.name.first_name
          end
        end

        context "and appeal id URL parameter not is passed" do
          it "succeeds" do
            get :list
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["data"]
            expect(response_body.first["attributes"]["veteran_first_name"]).to eq appeals.first.veteran_first_name
            expect(response_body.first["attributes"]["veteran_last_name"]).to eq appeals.first.veteran_last_name
            expect(response_body.first["attributes"]["file_number"]).to eq appeals.first.veteran_file_number

            expect(response_body.second["attributes"]["veteran_first_name"]).to eq appeals.second.veteran_first_name
            expect(response_body.second["attributes"]["veteran_last_name"]).to eq appeals.second.veteran_last_name
            expect(response_body.second["attributes"]["file_number"]).to eq appeals.second.veteran_file_number
          end
        end

        context "and AMA appeal id URL parameter is passed" do
          before do
            allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poas_by_participant_ids).and_return(
              ama_appeals.first.claimants.first.participant_id => {
                representative_name: "POA Name",
                representative_type: "POA Attorney",
                participant_id: "600153863"
              }
            )
          end

          let(:params) { { appeal_id: ama_appeals.first.uuid } }
          let!(:request_issue1) { create(:request_issue, review_request: ama_appeals.first) }
          let!(:request_issue2) { create(:request_issue, review_request: ama_appeals.first) }
          let!(:case_review1) { create(:attorney_case_review, task_id: tasks.first.id) }
          let!(:case_review2) { create(:attorney_case_review, task_id: tasks.first.id) }

          context "and addresses should not be queried" do
            before do
              expect_any_instance_of(Fakes::BGSService).to_not receive(:find_address_by_participant_id)
            end

            it "succeeds and passes appeal info" do
              get :details, params: params
              expect(response.status).to eq 200
              response_body = JSON.parse(response.body)["data"]

              expect(response_body["attributes"]["veteran_first_name"]).to eq ama_appeals.first.veteran_first_name
              expect(response_body["attributes"]["veteran_last_name"]).to eq ama_appeals.first.veteran_last_name
              expect(response_body["attributes"]["veteran_name_suffix"]).to eq "II"
              expect(response_body["attributes"]["file_number"]).to eq ama_appeals.first.veteran_file_number
              expect(response_body["attributes"]["representative_type"]).to eq(
                ama_appeals.first.representative_type
              )
              expect(response_body["attributes"]["representative_address"]).to eq(nil)
              expect(response_body["attributes"]["aod"]).to eq ama_appeals.first.advanced_on_docket
              expect(response_body["attributes"]["cavc"]).to eq "not implemented"
              expect(response_body["attributes"]["issues"].first["program"]).to eq "Compensation"
              expect(response_body["attributes"]["issues"].second["program"]).to eq "Compensation"
              expect(response_body["attributes"]["status"]).to eq nil
              expect(response_body["attributes"]["veteran_is_deceased"]).to eq true
              expect(response_body["attributes"]["veteran_death_date"]).to eq "05/25/2016"
              expect(response_body["attributes"]["appellant_is_not_veteran"]).to eq true
              expect(response_body["attributes"]["appellants"][0]["first_name"])
                .to eq ama_appeals.first.appellant_first_name
              expect(response_body["attributes"]["appellants"][0]["last_name"])
                .to eq ama_appeals.first.appellant_last_name
              expect(response_body["attributes"]["appellants"][1]["first_name"])
                .to eq ama_appeals.first.claimants.second.first_name
              expect(response_body["attributes"]["appellants"][1]["last_name"])
                .to eq ama_appeals.first.claimants.second.last_name
              expect(response_body["attributes"]["assigned_by"]).to eq tasks.first.assigned_by.full_name
              expect(response_body["attributes"]["documents"].size).to eq 2
              expect(response_body["attributes"]["documents"].first["written_by"]).to eq case_review1.attorney.full_name
              expect(response_body["attributes"]["documents"].first["document_id"]).to eq case_review1.document_id
              expect(response_body["attributes"]["documents"].second["written_by"])
                .to eq case_review2.attorney.full_name
              expect(response_body["attributes"]["documents"].second["document_id"]).to eq case_review2.document_id
            end
          end

          context "and the user is from dispatch" do
            # BVATEST1 is defined in Constants::BvaDispatchTeams
            let(:user) { create(:user, css_id: "BVATEST1", full_name: "George Michael") }

            before do
              allow_any_instance_of(Fakes::BGSService).to receive(:find_address_by_participant_id).and_return(
                address_line_1: "1234 K St.",
                address_line_2: "APT 3",
                address_line_3: "",
                city: "Washington",
                country: "USA",
                state: "CA",
                zip: "20001"
              )
            end

            it "succeeds and passes address info" do
              get :details, params: params
              expect(response.status).to eq 200
              response_body = JSON.parse(response.body)["data"]

              expect(response_body["attributes"]["representative_address"]).to eq(
                ama_appeals.first.representative_address.stringify_keys
              )
              expect(response_body["attributes"]["appellants"][0]["address"]["address_line_1"])
                .to eq ama_appeals.first.claimants.first.address_line_1
              expect(response_body["attributes"]["appellants"][0]["address"]["city"])
                .to eq ama_appeals.first.claimants.first.city
              expect(response_body["attributes"]["appellants"][1]["address"]["address_line_1"])
                .to eq ama_appeals.first.claimants.second.address_line_1
              expect(response_body["attributes"]["appellants"][1]["address"]["city"])
                .to eq ama_appeals.first.claimants.second.city
            end
          end
        end

        context "and legacy appeal id URL parameter is passed" do
          let(:params) { { appeal_id: appeals.first.vacols_id } }

          it "succeeds and passes appeal info" do
            get :details, params: params
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["data"]

            expect(response_body["attributes"]["veteran_first_name"]).to eq appeals.first.veteran_first_name
            expect(response_body["attributes"]["veteran_last_name"]).to eq appeals.first.veteran_last_name
            expect(response_body["attributes"]["veteran_name_suffix"]).to eq "PhD"
            expect(response_body["attributes"]["file_number"]).to eq appeals.first.veteran_file_number
            expect(response_body["attributes"]["representative_type"]).to eq(
              appeals.first.power_of_attorney.vacols_representative_type
            )
            expect(response_body["attributes"]["aod"]).to eq appeals.first.aod
            expect(response_body["attributes"]["cavc"]).to eq appeals.first.cavc
            expect(response_body["attributes"]["issues"]).to eq appeals.first.issues
            expect(response_body["attributes"]["status"]).to eq appeals.first.status
            expect(response_body["attributes"]["veteran_is_deceased"]).to eq appeals.first.veteran_is_deceased
            expect(response_body["attributes"]["veteran_death_date"]).to eq appeals.first.veteran_death_date
            expect(response_body["attributes"]["appellant_is_not_veteran"]).to eq !!appeals.first.appellant_first_name
          end

          context "and case is selected for quality review and has outstanding mail" do
            let(:assigner) { create(:user, css_id: "ANOTHER_TEST_ID", full_name: "Lyor Cohen") }

            let(:appeals) do
              c = create(:case,
                         :outstanding_mail,
                         :selected_for_quality_review,
                         :assigned,
                         user: user,
                         document_id: "1234",
                         assigner: assigner)
              [create(:legacy_appeal, vacols_case: c)]
            end

            it "returns the correct values for the appeal" do
              get :details, params: params
              expect(response.status).to eq 200
              response_body = JSON.parse(response.body)["data"]

              expect(response_body["attributes"]["previously_selected_for_quality_review"]).to eq true
              expect(response_body["attributes"]["outstanding_mail"]).to eq [
                { "outstanding" => false, "code" => "02", "description" => "Congressional Interest" },
                { "outstanding" => true, "code" => "05", "description" => "Evidence or Argument" }
              ]
              expect(response_body["attributes"]["assigned_by"]).to eq "Lyor Cohen"
            end

            it "filters out documents without ids and returns the correct doc values" do
              get :details, params: params
              expect(response.status).to eq 200
              response_body = JSON.parse(response.body)["data"]

              documents = response_body["attributes"]["documents"]
              expect(documents.length).to eq 1
              expect(documents[0]["written_by"]).to eq "George Michael"
              expect(documents[0]["document_id"]).to eq "1234"
            end
          end
        end
      end
    end
  end
end
