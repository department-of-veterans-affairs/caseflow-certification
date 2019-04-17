# frozen_string_literal: true

RSpec.describe Idt::Api::V1::VeteransController, type: :controller do
  describe "GET /idt/api/v1/veterans" do
    let(:user) { create(:user, css_id: "TEST_ID", full_name: "George Michael") }
    let(:token) do
      key, token = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      token
    end

    it_behaves_like "IDT access verification", :get, :details

    context "when request header contains valid token" do
      let(:role) { :attorney_role }

      before do
        create(:staff, role, sdomainid: user.css_id)
        request.headers["TOKEN"] = token
      end

      context "and a veteran's ssn" do
        let(:file_number) { "123456789" }
        let(:ssn) { file_number.to_s.reverse } # our fakes do this
        let!(:veteran) { create(:veteran, file_number: file_number) }
        let!(:power_of_attorney) { PowerOfAttorney.new(file_number: file_number) }
        let!(:power_of_attorney_address) { power_of_attorney.bgs_representative_address }

        before do
          request.headers["SSN"] = ssn
        end

        it "returns the veteran's details" do
          get :details
          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)

          expect(response_body["attributes"]["name"]["first_name"]).to eq veteran.first_name
          expect(response_body["attributes"]["name"]["last_name"]).to eq veteran.last_name
          expect(response_body["attributes"]["date_of_birth"]).to eq veteran.date_of_birth
          expect(response_body["attributes"]["date_of_death"]).to eq veteran.date_of_death
          expect(response_body["attributes"]["name_suffix"]).to eq veteran.name_suffix
          expect(response_body["attributes"]["gender"]).to eq veteran.gender
          expect(response_body["attributes"]["address_line_1"]).to eq veteran.address_line1
          expect(response_body["attributes"]["country"]).to eq veteran.country
          expect(response_body["attributes"]["zip"]).to eq veteran.zip_code
          expect(response_body["attributes"]["state"]).to eq veteran.state
          expect(response_body["attributes"]["city"]).to eq veteran.city
          expect(response_body["attributes"]["file_number"]).to eq veteran.file_number
          expect(response_body["attributes"]["participant_id"]).to eq veteran.participant_id
        end

        it "returns the veteran's poa" do
          get :details
          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)["attributes"]["poa"]
          response_address = response_body["representative_address"]

          expect(response_body["representative_type"]).to eq power_of_attorney.bgs_representative_type
          expect(response_body["representative_name"]).to eq power_of_attorney.bgs_representative_name
          expect(response_body["participant_id"]).to eq power_of_attorney.bgs_participant_id
          expect(response_address["address_line_1"]).to eq power_of_attorney_address[:address_line_1]
          expect(response_address["address_line_2"]).to eq power_of_attorney_address[:address_line_2]
          expect(response_address["address_line_3"]).to eq power_of_attorney_address[:address_line_3]
          expect(response_address["country"]).to eq power_of_attorney_address[:country]
          expect(response_address["zip"]).to eq power_of_attorney_address[:zip]
          expect(response_address["state"]).to eq power_of_attorney_address[:state]
          expect(response_address["city"]).to eq power_of_attorney_address[:city]
        end
      end

      context "but an invalid ssn" do
        before { request.headers["SSN"] = "123acb456" }

        it "returns 422 unprocessable entity " do
          get :details
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 422
          expect(response_body["message"]).to eq "Please enter a valid 9 digit SSN in the 'SSN' header"
        end
      end

      context "and no such veteran exists" do
        before { request.headers["SSN"] = "000000000" }

        it "returns 404 not found" do
          get :details
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 404
          expect(response_body["message"]).to eq "A veteran with that SSN was not found in our systems."
        end
      end
    end
  end
end
