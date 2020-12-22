# frozen_string_literal: true

class AdvanceOnDocketMotion < CaseflowRecord
  belongs_to :person
  belongs_to :user
  belongs_to :appeal, polymorphic: true

  validates :appeal, presence: true

  enum reason: {
    Constants.AOD_REASONS.financial_distress.to_sym => Constants.AOD_REASONS.financial_distress,
    Constants.AOD_REASONS.age.to_sym => Constants.AOD_REASONS.age,
    Constants.AOD_REASONS.serious_illness.to_sym => Constants.AOD_REASONS.serious_illness,
    Constants.AOD_REASONS.other.to_sym => Constants.AOD_REASONS.other
  }

  scope :granted, -> { where(granted: true) }
  scope :eligible_due_to_age, -> { age }
  scope :for_appeal, ->(appeal) { where(appeal: appeal) }
  # not(id: age) means to exclude AOD motions with reason="age" provided by the `age` enum
  scope :eligible_due_to_appeal, ->(appeal) { where(appeal: appeal).where.not(id: age) }
  scope :for_person, ->(person_id) { where(person_id: person_id) }

  def non_age_related_motion?
    [
      Constants.AOD_REASONS.financial_distress,
      Constants.AOD_REASONS.serious_illness,
      Constants.AOD_REASONS.other
    ].include?(reason)
  end

  class << self
    def granted_for_person?(person_id, appeal)
      eligible_motions(person_id, appeal).granted.any?
    end

    def eligible_motions(person_id, appeal)
      eligible_due_to_appeal(appeal)
        .or(eligible_due_to_age)
        .for_person(person_id)
    end

    def create_or_update_by_appeal(appeal, attrs)
      person_id = appeal.claimant.person.id
      motion = for_appeal(appeal).for_person(person_id).where(reason: attrs[:reason]).order(:id).last
      existing_motion = AdvanceOnDocketMotion.for_appeal(appeal).for_person(person_id).order(:id)

      if motion
        # We found an existing motion; update it
        motion.update(attrs)
      elsif another_non_age_motion_exists_in(existing_motion) && reason_is_not_age(attrs[:reason])
        # There is an existing non-age-related motion, but it is not what was passed to us.
        # Only one non-age-related motion (and one age-related motion) is allowed, so update an existing one:
        motion = existing_motion.reverse.find(&:non_age_related_motion?)
        motion.update(attrs)
      else
        # No existing motion of this type (age-related or non-age-related) exists, so create a new one:
        create(person_id: person_id, appeal: appeal).update(attrs)
      end
    end

    private

    def reason_is_not_age(reason)
      reason != Constants.AOD_REASONS.age
    end

    def another_non_age_motion_exists_in(motions)
      motions.any?(&:non_age_related_motion?)
    end
  end
end
