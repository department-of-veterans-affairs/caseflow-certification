class EndProduct
  include ActiveModel::Model
  include ActiveModel::Validations

  # NOTE: This is not a comprehensive list of possible statuses
  STATUSES = {
    "PEND" => "Pending",
    "CLR" => "Cleared",
    "CAN" => "Canceled"
  }.freeze

  INACTIVE_STATUSES = %w[CAN CLR CLD].freeze

  RAMP_CODES = {
    "682HLRRRAMP" => "Higher-Level Review Rating",
    "683SCRRRAMP" => "Supplemental Claim Review Rating"
  }.freeze

  DTA_CODES = {
    "040HDER" => "Supplemental Claim Rating DTA",
    "040HDENR" => "Supplemental Claim Nonrating DTA",
    "040HDERPMC" => "PMC HLR DTA Error - Rating",
    "040HDENRPMC" => "PMC HLR DTA Error - Non-Rating",
    "040BDE" => "Board DTA Error",
    "040BDEIMO" => "Board DTA Error with IMO",
    "040BDEPMC" => "PMC Board DTA Error",
    "040BDEIMOPMC" => "PMC Board DTA Error - w/IMO"
  }.freeze

  DECISION_REVIEW_CODES = {
    "030HLRR" => "Higher-Level Review Rating",
    "030HLRNR" => "Higher-Level Review Nonrating",
    "030HLRRPMC" => "PMC Higher-Level Review Rating",
    "030HLRNRPMC" => "PMC Higher-Level Review Non-Rating",
    "040SCR" => "Supplemental Claim Rating",
    "040SCNR" => "Supplemental Claim Nonrating",
    "040SCRPMC" => "PMC Supplemental Claim Rating",
    "040SCNRPMC" => "PMC Supplemental Claim Non-Rating"
  }.freeze

  EFFECTUATION_CODES = {
    "030BGR" => "Board Grant Rating",
    "030BGRNR" => "Board Grant Non-Rating",
    "030BGRPMC" => "PMC Board Grant Rating",
    "030BGNRPMC" => "PMC Board Grant Non-Rating"
  }.freeze

  DISPATCH_CODES = {
    # TODO(jd): Remove this when we've verified they are
    # no longer needed. Maybe 30 days after May 2017?
    # original dispatch codes
    "170APPACT" => "Appeal Action",
    "170APPACTPMC" => "PMC-Appeal Action",
    "170PGAMC" => "ARC-Partial Grant",
    "170RMD" => "Remand",
    "170RMDAMC" => "ARC-Remand",
    "170RMDPMC" => "PMC-Remand",
    "172GRANT" => "Grant of Benefits",
    "172BVAG" => "BVA Grant",
    "170RBVAG" => "Remand with BVA Grant",
    "172BVAGPMC" => "PMC-BVA Grant",
    "400CORRC" => "Correspondence",
    "400CORRCPMC" => "PMC-Correspondence",
    "930RC" => "Rating Control",
    "930RCPMC" => "PMC-Rating Control",

    # new ones released in May 2017
    "070BVAGR" => "BVA Grant (070)",
    "070BVAGRARC" => "ARC BVA Grant",
    "070BVAGRPMC" => "PMC BVA Grant (070)",
    "070RMND" => "Remand (070)",
    "070RMNDARC" => "ARC Remand (070)",
    "070RMNDPMC" => "PMC Remand (070)",
    "070RMNDBVAG" => "Remand with BVA Grant (070)",
    "070RMBVAGARC" => "ARC Remand with BVA Grant",
    "070RMBVAGPMC" => "PMC Remand with BVA Grant"
  }.freeze

  CODES = DISPATCH_CODES.merge(RAMP_CODES).merge(DECISION_REVIEW_CODES).merge(DTA_CODES).merge(EFFECTUATION_CODES)

  DISPATCH_MODIFIERS = %w[070 071 072 073 074 075 076 077 078 079 170 171 175 176 177 178 179 172].freeze

  DEFAULT_PAYEE_CODE = "00".freeze

  attr_accessor :claim_id, :claim_date, :claim_type_code, :modifier, :status_type_code, :last_action_date,
                :station_of_jurisdiction, :gulf_war_registry, :suppress_acknowledgement_letter, :payee_code,
                :claimant_last_name, :claimant_first_name

  attr_writer :claimant_participant_id, :benefit_type_code

  # Validators are used for validating the EP before we create it in VBMS
  validates :modifier, :claim_type_code, :station_of_jurisdiction, :claim_date, presence: true
  validates :claim_type_code, inclusion: { in: CODES.keys }
  validates :gulf_war_registry, :suppress_acknowledgement_letter, inclusion: { in: [true, false] }

  def benefit_type_code
    @benefit_type_code ||= Veteran::BENEFIT_TYPE_CODE_LIVE
  end

  def claimant_participant_id
    @claimant_participant_id ||= nil
  end

  def claim_type
    label || claim_type_code
  end

  def status_type
    STATUSES[status_type_code] || status_type_code
  end

  def matches?(end_product)
    claim_type_code == end_product.claim_type_code &&
      modifier == end_product.modifier &&
      claim_date.to_date == end_product.claim_date.to_date
  end

  # Does this EP have a modifier that might conflict with a new dispatch EP?
  def dispatch_conflict?
    dispatch_modifier? && active?
  end

  # Is this a potential match to be an existing ep for the appeal?
  def potential_match?(appeal)
    dispatch_code? && assignable? && near_decision_date_of?(appeal)
  end

  # TODO: change to more semantic names
  #       this will require JS change, need to wait for redux refactor
  def serializable_hash(_options)
    {
      benefit_claim_id: claim_id,
      claim_receive_date: claim_date.to_formatted_s(:short_date),
      claim_type_code: claim_type,
      end_product_type_code: modifier,
      status_type_code: status_type
    }
  end

  # this is used for intake
  def serialize
    {
      claim_id: claim_id,
      claim_type_code: claim_type_code
    }
  end

  def to_vbms_hash
    {
      benefit_type_code: benefit_type_code,
      payee_code: payee_code,
      predischarge: false,
      claim_type: "Claim",
      end_product_modifier: modifier,
      end_product_code: claim_type_code,
      end_product_label: claim_type,
      station_of_jurisdiction: station_of_jurisdiction,
      date: claim_date.to_date,
      suppress_acknowledgement_letter: suppress_acknowledgement_letter,
      gulf_war_registry: gulf_war_registry,
      claimant_participant_id: claimant_participant_id
    }
  end

  def description
    label && "#{claim_type_code} - #{label}"
  end

  def description_with_routing
    "#{description} for #{station_description}"
  end

  def station_description
    regional_office ? regional_office.station_description : "Unknown"
  end

  def active?
    !INACTIVE_STATUSES.include?(status_type_code)
  end

  def contentions
    @contentions ||= claim_id ? VBMSService.fetch_contentions(claim_id: claim_id) : nil
  end

  def ramp?
    RAMP_CODES.key?(claim_type_code)
  end

  private

  def label
    @label ||= CODES[claim_type_code]
  end

  def near_decision_date_of?(appeal)
    (claim_date - appeal.decision_date).abs < 30.days
  end

  def dispatch_code?
    DISPATCH_CODES.key?(claim_type_code)
  end

  def dispatch_modifier?
    DISPATCH_MODIFIERS.include?(modifier)
  end

  def assignable?
    status_type_code != "CAN"
  end

  def regional_office
    @regional_office ||= RegionalOffice.for_station(station_of_jurisdiction).first
  end

  class << self
    # If you change this method, you will need to clear cache in prod for your changes to
    # take effect immediately. See DecisionReview#cached_serialized_ratings
    def deserialize(end_product_hash)
      new(
        claim_id: end_product_hash[:claim_id],
        claim_type_code: end_product_hash[:claim_type_code]
      )
    end

    def from_bgs_hash(hash)
      new(
        claim_id: hash[:benefit_claim_id],
        claim_date: parse_claim_date(hash[:claim_receive_date]),
        claim_type_code: hash[:claim_type_code],
        modifier: hash[:end_product_type_code],
        status_type_code: hash[:status_type_code],
        last_action_date: parse_claim_date(hash[:last_action_date]).to_date,
        claimant_first_name: hash[:claimant_first_name],
        claimant_last_name: hash[:claimant_last_name],
        payee_code: hash[:payee_type_code]
      )
    end

    def from_establish_claim_params(hash)
      new(
        claim_date: parse_claim_date(hash[:date]),
        claim_type_code: hash[:end_product_code],
        modifier: hash[:end_product_modifier],
        suppress_acknowledgement_letter: hash[:suppress_acknowledgement_letter],
        gulf_war_registry: hash[:gulf_war_registry],
        station_of_jurisdiction: hash[:station_of_jurisdiction],
        payee_code: hash[:payee_code] || DEFAULT_PAYEE_CODE
      )
    end

    private

    def parse_claim_date(date)
      return unless date

      Date.strptime(date, "%m/%d/%Y").in_time_zone
    end
  end
end
