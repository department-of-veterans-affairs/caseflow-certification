# rubocop:disable Metrics/ClassLength
require "bgs"

class Fakes::BGSService
  include PowerOfAttorneyMapper
  include AddressMapper

  cattr_accessor :end_product_records
  cattr_accessor :inaccessible_appeal_vbms_ids
  cattr_accessor :veteran_records
  cattr_accessor :power_of_attorney_records
  cattr_accessor :address_records
  cattr_accessor :ssn_not_found
  cattr_accessor :rating_records
  cattr_accessor :rating_issue_records
  attr_accessor :client

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  def self.create_veteran_records
    return if @veteran_records_created

    @veteran_records_created = true

    file_path = Rails.root.join("local", "vacols", "bgs_setup.csv")

    CSV.foreach(file_path, headers: true) do |row|
      row_hash = row.to_h
      veteran = Generators::Veteran.build(file_number: row_hash["vbms_id"].chop)

      case row_hash["bgs_key"]
      when "has_rating"
        Generators::Rating.build(
          participant_id: veteran.participant_id
        )
      when "has_many_ratings"
        Generators::Rating.build(
          participant_id: veteran.participant_id
        )
        Generators::Rating.build(
          participant_id: veteran.participant_id,
          promulgation_date: Time.zone.today - 60,
          issues: [
            { decision_text: "Left knee" },
            { decision_text: "PTSD" }
          ]
        )
      when "has_supplemental_claim_with_vbms_claim_id"
        claim_id = "600118926"
        sc = SupplementalClaim.find_or_create_by!(
          veteran_file_number: veteran.file_number
        )
        EndProductEstablishment.find_or_create_by!(
          reference_id: claim_id,
          veteran_file_number: veteran.file_number,
          source: sc
        )
        sc
      when "has_higher_level_review_with_vbms_claim_id"
        claim_id = "600118951"
        hlr = HigherLevelReview.find_or_create_by!(
          veteran_file_number: veteran.file_number
        )
        EndProductEstablishment.find_or_create_by!(
          reference_id: claim_id,
          veteran_file_number: veteran.file_number,
          source: hlr
        )
        hlr
      when "has_ramp_election_with_contentions"
        claim_id = "123456"
        ramp_election = RampElection.find_or_create_by!(
          veteran_file_number: veteran.file_number
        )
        EndProductEstablishment.find_or_create_by!(
          reference_id: claim_id,
          veteran_file_number: veteran.file_number,
          source: ramp_election,
          synced_status: "CLR",
          last_synced_at: 10.minutes.ago
        )
        Generators::Contention.build(text: "A contention!", claim_id: claim_id)
        ramp_election
      end
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity

  def self.all_grants
    default_date = 10.days.ago.to_formatted_s(:short_date)
    [
      {
        benefit_claim_id: "1",
        claim_receive_date: 20.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070BVAGR",
        end_product_type_code: "070",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "2",
        claim_receive_date: default_date,
        claim_type_code: "070RMND",
        end_product_type_code: "070",
        status_type_code: "CLR"
      },
      {
        benefit_claim_id: "3",
        claim_receive_date: Time.zone.now.to_formatted_s(:short_date),
        claim_type_code: "070BVAGR",
        end_product_type_code: "071",
        status_type_code: "CAN"
      },
      {
        benefit_claim_id: "4",
        claim_receive_date: 200.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070BVAGR",
        end_product_type_code: "072",
        status_type_code: "CLR"
      },
      {
        benefit_claim_id: "5",
        claim_receive_date: default_date,
        claim_type_code: "170APPACT",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "6",
        claim_receive_date: default_date,
        claim_type_code: "170APPACTPMC",
        end_product_type_code: "171",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "7",
        claim_receive_date: default_date,
        claim_type_code: "170PGAMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "8",
        claim_receive_date: default_date,
        claim_type_code: "170RMD",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "9",
        claim_receive_date: default_date,
        claim_type_code: "170RMDAMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "10",
        claim_receive_date: default_date,
        claim_type_code: "170RMDPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "11",
        claim_receive_date: default_date,
        claim_type_code: "070BVAGRARC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "12",
        claim_receive_date: default_date,
        claim_type_code: "172BVAG",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "13",
        claim_receive_date: default_date,
        claim_type_code: "172BVAGPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "14",
        claim_receive_date: default_date,
        claim_type_code: "400CORRC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "15",
        claim_receive_date: default_date,
        claim_type_code: "400CORRCPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "16",
        claim_receive_date: default_date,
        claim_type_code: "930RC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "17",
        claim_receive_date: default_date,
        claim_type_code: "930RCPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      }
    ]
  end
  # rubocop:enable Metrics/MethodLength

  def self.existing_full_grants
    [
      {
        benefit_claim_id: "1",
        claim_receive_date: 20.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070BVAGR",
        end_product_type_code: "070",
        status_type_code: "PEND"
      }
    ]
  end

  # rubocop:disable Metrics/MethodLength
  def self.existing_partial_grants
    [
      {
        benefit_claim_id: "1",
        claim_receive_date: 10.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070RMBVAGARC",
        end_product_type_code: "070",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "2",
        claim_receive_date: 10.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070RMBVAGARC",
        end_product_type_code: "071",
        status_type_code: "CLR"
      },
      {
        benefit_claim_id: "3",
        claim_receive_date: 200.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070RMBVAGARC",
        end_product_type_code: "072",
        status_type_code: "PEND"
      }
    ]
  end
  # rubocop:enable Metrics/MethodLength

  def self.no_grants
    []
  end

  def self.power_of_attorney_records
    {
      "111225555" =>
        {
          file_number: "111225555",
          power_of_attorney:
            {
              legacy_poa_cd: "3QQ",
              nm: "Clarence Darrow",
              org_type_nm: "POA Attorney",
              ptcpnt_id: "ERROR-ID"
            },
          ptcpnt_id: "600085545"
        }
    }
  end

  def self.clean!
    self.ssn_not_found = false
    self.inaccessible_appeal_vbms_ids = []
    self.end_product_records = {}
    self.rating_records = {}
    self.rating_issue_records = {}
  end

  def get_end_products(veteran_id)
    records = self.class.end_product_records || {}

    records[veteran_id] || records[:default] || []
  end

  def fetch_veteran_info(vbms_id)
    # BGS throws a ShareError if the veteran has too high sensitivity
    fail BGS::ShareError, "Sensitive File - Access Violation !" unless can_access?(vbms_id)

    (self.class.veteran_records || {})[vbms_id]
  end

  # rubocop:disable Metrics/MethodLength
  def fetch_person_info(participant_id)
    # This is a limited set of test data, more fields are available.
    if participant_id == "5382910292"
      # This claimant is over 75 years old so they get automatic AOD
      {
        birth_date: "Sun, 05 Sep 1943 00:00:00 -0500",
        first_name: "Bob",
        middle_name: "Billy",
        last_name: "Vance"
      }
    elsif participant_id == "1129318238"
      {
        birth_date: "Sat, 05 Sep 1998 00:00:00 -0500",
        first_name: "Cathy",
        middle_name: "",
        last_name: "Smith"
      }
    else
      {
        birth_date: "Sat, 05 Sep 1998 00:00:00 -0500",
        first_name: "Tom",
        middle_name: "Edward",
        last_name: "Brady"
      }
    end
  end
  # rubocop:enable Metrics/MethodLength

  def can_access?(vbms_id)
    !(self.class.inaccessible_appeal_vbms_ids || []).include?(vbms_id)
  end

  # TODO: add more test cases
  def fetch_poa_by_file_number(file_number)
    record = (self.class.power_of_attorney_records || {})[file_number]
    record ||= default_vso_power_of_attorney_record if file_number == 216_979_849
    record ||= default_power_of_attorney_record

    get_poa_from_bgs_poa(record[:power_of_attorney])
  end

  def fetch_poas_by_participant_id(participant_id)
    if participant_id == VSO_PARTICIPANT_ID
      return default_vsos_by_participant_id.map { |poa| get_poa_from_bgs_poa(poa) }
    end
    []
  end

  # rubocop:disable Metrics/MethodLength
  def fetch_poas_by_participant_ids(participant_ids)
    get_hash_of_poa_from_bgs_poas(
      participant_ids.map do |participant_id|
        vso = if participant_id == "CLAIMANT_WITH_PVA_AS_VSO"
                {
                  legacy_poa_cd: "071",
                  nm: "PARALYZED VETERANS OF AMERICA, INC.",
                  org_type_nm: "POA National Organization",
                  ptcpnt_id: "2452383"
                }
              else
                {
                  legacy_poa_cd: "100",
                  nm: "Attorney McAttorneyFace",
                  org_type_nm: "POA Attorney",
                  ptcpnt_id: "1234567"
                }
              end

        {
          ptcpnt_id: participant_id,
          power_of_attorney: vso
        }
      end
    )
  end
  # rubocop:enable Metrics/MethodLength

  # TODO: add more test cases
  def find_address_by_participant_id(participant_id)
    address = (self.class.address_records || {})[participant_id]
    address ||= default_address

    get_address_from_bgs_address(address)
  end

  def fetch_claimant_info_by_participant_id(_participant_id)
    default_claimant_info
  end

  def fetch_file_number_by_ssn(ssn)
    ssn_not_found ? nil : ssn
  end

  def fetch_ratings_in_range(participant_id:, start_date:, end_date:)
    ratings = (self.class.rating_records || {})[participant_id]

    # Simulate the error bgs throws if participant doesn't exist or doesn't have any ratings
    unless ratings
      fail Savon::Error, "java.lang.IndexOutOfBoundsException: Index: 0, Size: 0"
    end

    ratings = ratings.select do |r|
      start_date <= r[:prmlgn_dt] && end_date >= r[:prmlgn_dt]
    end

    # BGS returns the data not as an array if there is only one rating
    ratings = ratings.first if ratings.count == 1

    { rating_profile_list: ratings.empty? ? nil : { rating_profile: ratings } }
  end

  def fetch_rating_profile(participant_id:, profile_date:)
    self.class.rating_issue_records ||= {}
    self.class.rating_issue_records[participant_id] ||= {}

    rating_issues = self.class.rating_issue_records[participant_id][profile_date]

    # Simulate the error bgs throws if rating profile doesn't exist
    unless rating_issues
      fail Savon::Error, "a record does not exist for PTCPNT_VET_ID = '#{participant_id}'"\
        " and PRFL_DT = '#{profile_date}'"
    end

    # Simulate BGS issue where no rating issues are returned in the response
    return { rating_issues: [] } if rating_issues == :no_issues

    # BGS returns the data not as an array if there is only one issue
    rating_issues = rating_issues.first if rating_issues.count == 1

    { rating_issues: rating_issues }
  end

  def get_participant_id_for_user(user)
    return VSO_PARTICIPANT_ID if user.css_id == "VSO"
    DEFAULT_PARTICIPANT_ID
  end

  # rubocop:disable Metrics/MethodLength
  def find_all_relationships(*)
    [
      {
        authzn_change_clmant_addrs_ind: nil,
        authzn_poa_access_ind: "Y",
        award_begin_date: nil,
        award_end_date: nil,
        award_ind: "N",
        award_type: "CPL",
        date_of_birth: "02171972",
        date_of_death: "03072014",
        dependent_reason: nil,
        dependent_terminate_date: nil,
        email_address: nil,
        fiduciary: nil,
        file_number: "123456789",
        first_name: "BOB",
        gender: "M",
        last_name: "VANCE",
        middle_name: "D",
        poa: "DISABLED AMERICAN VETERANS",
        proof_of_dependecy_ind: nil,
        ptcpnt_id: "CLAIMANT_WITH_PVA_AS_VSO",
        relationship_begin_date: nil,
        relationship_end_date: nil,
        relationship_type: "Spouse",
        ssn: "123456789",
        ssn_verified_ind: "Unverified",
        terminate_reason: nil
      },
      {
        authzn_change_clmant_addrs_ind: nil,
        authzn_poa_access_ind: nil,
        award_begin_date: nil,
        award_end_date: nil,
        award_ind: "N",
        award_type: "CPL",
        date_of_birth: "04121995",
        date_of_death: nil,
        dependent_reason: nil,
        dependent_terminate_date: nil,
        email_address: "cathy@gmail.com",
        fiduciary: nil,
        file_number: nil,
        first_name: "CATHY",
        gender: nil,
        last_name: "SMITH",
        middle_name: nil,
        poa: nil,
        proof_of_dependecy_ind: nil,
        ptcpnt_id: "1129318238",
        relationship_begin_date: "08121999",
        relationship_end_date: nil,
        relationship_type: "Child",
        ssn: nil,
        ssn_verified_ind: nil,
        terminate_reason: nil
      }
    ]
  end
  # rubocop:enable Metrics/MethodLength

  private

  VSO_PARTICIPANT_ID = "4623321".freeze
  DEFAULT_PARTICIPANT_ID = "781162".freeze

  def default_claimant_info
    {
      relationship: "Spouse"
    }
  end

  def default_power_of_attorney_record
    {
      file_number: "633792224",
      power_of_attorney:
        {
          legacy_poa_cd: "3QQ",
          nm: "Clarence Darrow",
          org_type_nm: "POA Attorney",
          ptcpnt_id: "600153863"
        },
      ptcpnt_id: "600085544"
    }
  end

  def default_vso_power_of_attorney_record
    {
      file_number: "216979849",
      power_of_attorney:
        {
          legacy_poa_cd: "070",
          nm: "VIETNAM VETERANS OF AMERICA",
          org_type_nm: "POA National Organization",
          ptcpnt_id: "2452415"
        },
      ptcpnt_id: "600085544"
    }
  end

  def default_vsos_by_participant_id
    [
      {
        legacy_poa_cd: "070",
        nm: "VIETNAM VETERANS OF AMERICA",
        org_type_nm: "POA National Organization",
        ptcpnt_id: "2452415"
      },
      {
        legacy_poa_cd: "071",
        nm: "PARALYZED VETERANS OF AMERICA, INC.",
        org_type_nm: "POA National Organization",
        ptcpnt_id: "2452383"
      }
    ]
  end

  # rubocop:disable Metrics/MethodLength
  def default_address
    {
      addrs_one_txt: "9999 MISSION ST",
      addrs_three_txt: "APT 2",
      addrs_two_txt: "UBER",
      city_nm: "SAN FRANCISCO",
      cntry_nm: "USA",
      efctv_dt: 15.days.ago.to_formatted_s(:short_date),
      jrn_dt: 15.days.ago.to_formatted_s(:short_date),
      jrn_lctn_id: "283",
      jrn_obj_id: "SHARE  - PCAN",
      jrn_status_type_cd: "U",
      jrn_user_id: "CASEFLOW1",
      postal_cd: "CA",
      ptcpnt_addrs_id: "15069061",
      ptcpnt_addrs_type_nm: "Mailing",
      ptcpnt_id: "600085544",
      shared_addrs_ind: "N",
      trsury_addrs_four_txt: "SAN FRANCISCO CA",
      trsury_addrs_one_txt: "Jamie Fakerton",
      trsury_addrs_three_txt: "APT 2",
      trsury_addrs_two_txt: "9999 MISSION ST",
      trsury_seq_nbr: "5",
      zip_prefix_nbr: "94103"
    }
  end
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/ClassLength
