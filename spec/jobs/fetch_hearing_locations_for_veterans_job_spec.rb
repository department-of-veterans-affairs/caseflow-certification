require "rails_helper"
require "faker"

describe FetchHearingLocationsForVeteransJob, focus: true do
  let!(:job) { FetchHearingLocationsForVeteransJob.new }

  context "when there is a case in location 57 *without* an associated veteran" do
    let!(:bfcorlid) { "123456789S" }
    let!(:bfcorlid_file_number) { "123456789" }
    let!(:vacols_case) { create(:case, bfcurloc: 57, bfregoff: "RO01", bfcorlid: "123456789S") }

    before(:each) do
      Fakes::BGSService.veteran_records = { "123456789" => veteran_record(file_number: "123456789S") }
    end

    describe "#create_missing_veterans" do
      it "creates a veteran" do
        job.create_missing_veterans
        expect(Veteran.where(file_number: bfcorlid_file_number).count).to eq 1
      end
    end

    describe "#fetch_and_update_ro_for_veteran" do
      let(:veteran) { create(:veteran, file_number: bfcorlid_file_number) }

      context "when legacy RO is defined" do
        let(:expected_ro) { "EXPECTEDRO" }
        let(:vacols_case) { create(:case, bfcurloc: 57, bfregoff: expected_ro, bfcorlid: bfcorlid) }

        it "updates veteran hearing_regional_office with legacy RO" do
          job.find_or_update_ro_for_veteran(veteran, 0.0, 0.0)
          expect(Veteran.first.hearing_regional_office).to eq expected_ro
        end
      end

      context "when legacy RO is not defined" do
        let(:expected_ro) { RegionalOffice::CITIES.keys[0] }
        let(:vacols_case) { create(:case, bfcurloc: 57, bfregoff: nil, bfcorlid: bfcorlid) }

        before do
          VADotGovService = ExternalApi::VADotGovService

          facility_ros = RegionalOffice::CITIES.values.reject { |ro| ro[:facility_locator_id].nil? }
          body = mock_distance_body(
            data: facility_ros.map { |ro| mock_data(id: ro[:facility_locator_id]) },
            distances: facility_ros.map.with_index do |ro, index|
              mock_distance(distance: index, id: ro[:facility_locator_id])
            end
          )
          distance_response = HTTPI::Response.new(200, [], body.to_json)
          allow(MetricsService).to receive(:record).with(/GET/, any_args).and_return(distance_response)
          allow(HTTPI).to receive(:get).with(instance_of(HTTPI::Request)).and_return(distance_response)
        end

        it "updates veteran hearing_regional_office with fetched RO" do
          job.find_or_update_ro_for_veteran(veteran, 0.0, 0.0)
          expect(Veteran.first.hearing_regional_office).to eq expected_ro
        end

        context "and existing hearing_regional_office is defined but no legacy RO" do
          let(:expected_ro) { "EXISTINGRO" }
          let(:vacols_case) { create(:case, bfcurloc: 57, bfregoff: nil, bfcorlid: bfcorlid) }
          let(:veteran) { create(:veteran, file_number: bfcorlid_file_number, hearing_regional_office: expected_ro) }

          it "the veteran's hearing_regional_office does not update" do
            job.find_or_update_ro_for_veteran(veteran, 0.0, 0.0)
            expect(Veteran.first.hearing_regional_office).to eq expected_ro
          end
        end
      end
    end

    describe "#perform" do
      before do
        VADotGovService = ExternalApi::VADotGovService

        expect(DataDogService).to receive(:emit_gauge).with(hash_including(metric_name: "pages_requested"), any_args).and_return("") # rubocop:disable Metrics/LineLength

        distance_response = HTTPI::Response.new(200, [], mock_distance_body(distance: 11.11).to_json)
        allow(MetricsService).to receive(:record).with(/GET/, any_args).and_return(distance_response).once
        allow(HTTPI).to receive(:get).with(instance_of(HTTPI::Request)).and_return(distance_response)

        geocode_response = HTTPI::Response.new(200, [], mock_geocode_body.to_json)
        allow(MetricsService).to receive(:record).with(/POST/, any_args).and_return(geocode_response).once
        allow(HTTPI).to receive(:post).with(instance_of(HTTPI::Request)).and_return(geocode_response)
      end

      it "creates an available hearing location" do
        FetchHearingLocationsForVeteransJob.perform_now
        expect(AvailableHearingLocations.count).to eq 1
        expect(AvailableHearingLocations.first.distance).to eq 11.11
      end
    end

    context "and a veteran with an available location defined more than a month ago exists" do
      before do
        create(:case, bfcurloc: 57, bfregoff: "RO01", bfcorlid: "246810120S")
        create(:veteran, file_number: "246810120")
        create(:available_hearing_locations, veteran_file_number: "246810120", updated_at: 2.months.ago)
      end

      describe "#veterans" do
        it "returns both veterans" do
          job.create_missing_veterans
          expect(job.veterans.count).to eq 2
        end
      end
    end

    context "and a veteran with an available location defined today" do
      before do
        create(:case, bfcurloc: 57, bfregoff: "RO01", bfcorlid: "246810120S")
        create(:veteran, file_number: "246810120")
        create(:available_hearing_locations, veteran_file_number: "246810120")
      end

      describe "#veterans" do
        it "returns one veteran" do
          job.create_missing_veterans
          expect(job.veterans.count).to eq 1
          expect(job.veterans.first.file_number).to eq bfcorlid_file_number
        end
      end
    end

    context "and a case exists in a location other than 57" do
      before do
        create(:case, bfcurloc: 67, bfregoff: "RO10", bfcorlid: "987654321")
      end

      describe "#file_numbers" do
        it "only returns file numbers from location 57" do
          expect(job.file_numbers).to match_array [bfcorlid_file_number]
        end
      end
    end

    context "and an additional case exists in location 57 *with* an associated veteran" do
      before do
        create(:case, bfcurloc: 57, bfregoff: "RO01", bfcorlid: "987654321")
        create(:veteran, file_number: "987654321")
      end

      describe "#missing_veteran_file_numbers" do
        it "returns list of file_numbers with no associated veteran" do
          expect(job.missing_veteran_file_numbers).to match_array [bfcorlid_file_number]
        end
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def veteran_record(file_number:)
    {
      file_number: file_number,
      ptcpnt_id: "123123",
      sex: "M",
      first_name: "June",
      middle_name: "Janice",
      last_name: "Juniper",
      name_suffix: "II",
      ssn: "123456789",
      address_line1: "122 Mullberry St.",
      address_line2: "PO BOX 123",
      address_line3: "",
      city: "Roanoke",
      state: "VA",
      country: "USA",
      date_of_birth: "1977-07-07",
      zip_code: "99999",
      military_post_office_type_code: "99999",
      military_postal_type_code: "99999",
      service: "99999"
    }
  end

  def mock_geocode_body(lat: 38.768185, long: -77.450033)
    {
      "address": {
        "county": {
          "name": "Manassas Park City"
        },
        "stateProvince": {
          "name": "Virginia",
          "code": "VA"
        },
        "country": {
          "name": "United States",
          "code": "USA"
        },
        "addressLine1": "8633 Union Pl",
        "city": "Manassas Park",
        "zipCode5": "20111"
      },
      "geocode": {
        "latitude": lat,
        "longitude": long
      }
    }
  end

  def mock_distance_body(distance: 0.0, id: "vba_301", data: nil, distances: nil)
    {
      "data": data || [mock_data(id: id)],
      "links": {
        "next": nil
      },
      "meta": {
        "distances": distances || [mock_distance(distance: distance, id: id)]
      }
    }
  end

  def mock_data(id:)
    {
      "id": id,
      "type": "va_facilities",
      "attributes": {
        "name": "Holdrege VA Clinic",
        "facility_type": "va_health_facility",
        "lat": 40.4454392100001,
        "long": -99.37959413,
        "address": {
          "physical": {
            "zip": "68949-1705",
            "city": "Holdrege",
            "state": "NE",
            "address_1": "1118 Burlington Street",
            "address_2": "",
            "address_3": nil
          }
        }
      }
    }
  end

  def mock_distance(distance:, id:)
    {
      "id": id,
      "distance": distance
    }
  end
  # rubocop:enable Metrics/MethodLength
end
