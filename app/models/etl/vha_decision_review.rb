# frozen_string_literal: true

# Model to capture reporting data scoped to those Decision Reviews (Appeal, HLR, SC)
# that have an associated benefit type corresponding to VHA.
#
# This includes the following tables:
#   * HIGHER_LEVEL_REVIEWS: Intake data for Higher level Reviews
#   * SUPPLEMENTAL CLAIMS: Intake data for Supplemental Claims
#   * APPEALS: Used to keep track of information for AMA appeals
#
# To make it simple for VHA to pull the data they need, we're reporting data as a single table.

class ETL::VhaDecisionReview < ETL::Record
  self.inheritance_column = :decision_review_type

  STI_TYPE_HASH = {
    Appeal.name => ETL::VhaAppeal.name,
    HigherLevelReview.name => ETL::VhaHigherLevelReview.name,
    SupplementalClaim.name => ETL::VhaSupplementalClaim.name
  }.freeze

  INVERTED_STI_TYPE_HASH = STI_TYPE_HASH.invert

  class << self
    def find_sti_class(type_name)
      puts "------- #{type_name}"
      super(STI_TYPE_HASH[type_name])
    end

    def sti_name
      puts "======= #{self.name}"
      INVERTED_STI_TYPE_HASH[self.name]
    end

    private

    def common_decision_review_attributes
      [
        :benefit_type,
        :establishment_processed_at,
        :establishment_submitted_at,
        :legacy_opt_in_approved,
        :receipt_date,
        :uuid,
        :veteran_file_number,
        :veteran_is_not_claimant
      ]
    end

    def unique_higher_level_review_attributes
      [
        :informal_conference,
        :same_office
      ]
    end

    def unique_supplemental_claim_attributes
      [
        :decision_review_remanded_id,
        :decision_review_remanded_type
      ]
    end

    def unique_appeal_attributes
      [
        :closest_regional_office,
        :docket_range_date,
        :docket_type,
        :established_at,
        :poa_participant_id,
        :stream_docket_number,
        :stream_type,
        :target_decision_date
      ]
    end

    def unique_attributes_method_name(klass)
      "unique_#{klass.underscore}_attributes".to_sym
    end

    def merge_original_attributes_to_target(original, target)
      target.decision_review_created_at = original.created_at
      target.decision_review_updated_at = original.updated_at

      target.decision_review_id = original.id
      target.decision_review_type = original.class.name

      common_decision_review_attributes.each do |attr|
        target[attr] = original[attr]
      end

      send(unique_attributes_method_name, original.class.name).each do |attr|
        target[attr] = original[attr]
      end

      # to do: based on VHA feedback we might need to add more calculated values

      target
    end
  end
end
