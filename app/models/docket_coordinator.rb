# frozen_string_literal: true

class DocketCoordinator
  # MINIMUM_LEGACY_PROPORTION + MAXIMUM_DIRECT_REVIEW_PROPORTION cannot exceed 1.
  MINIMUM_LEGACY_PROPORTION = 0.1
  MAXIMUM_DIRECT_REVIEW_PROPORTION = 0.8

  # A lever controlling how many direct review docket appeals are distributed before the time goal is reached.
  # A lower number will distribute fewer appeals, accelerating faster toward the time goal.
  INTERPOLATED_DIRECT_REVIEW_PROPORTION_ADJUSTMENT = 0.67

  def dockets
    @dockets ||= {
      legacy: LegacyDocket.new,
      direct_review: DirectReviewDocket.new,
      evidence_submission: EvidenceSubmissionDocket.new,
      hearing: HearingRequestDocket.new
    }
  end

  def docket_proportions
    return @docket_proportions if @docket_proportions

    # We distribute appeals proportional to each docket's "weight," basically the number of pending appeals.
    # LegacyDocket makes adjustments to the weight to account for pre-Form 9 appeals.
    @docket_proportions = dockets
      .transform_values(&:weight)
      .extend(ProportionHash)

    # Prevent divide by zero errors if 100% of the docket margin is priority.
    return @docket_proportions.normalize! if docket_margin_net_of_priority == 0

    # Unlike the other dockets, the direct review docket observes a time goal.
    # We distribute appeals from the docket sufficient to meet the goal, instead of proportionally.
    # When there are no or few "due" direct review appeals, we instead calculate a curve out.
    direct_review_proportion = (direct_review_due_count.to_f / docket_margin_net_of_priority)
      .clamp(interpolated_minimum_direct_review_proportion, MAXIMUM_DIRECT_REVIEW_PROPORTION)

    @docket_proportions.add_fixed_proportions!(direct_review: direct_review_proportion)

    # The legacy docket proportion is subject to a minimum, provided we have at least that many legacy appeals.
    if @docket_proportions[:legacy] < MINIMUM_LEGACY_PROPORTION
      legacy_proportion = [
        MINIMUM_LEGACY_PROPORTION,
        dockets[:legacy].count(priority: false, ready: true).to_f / docket_margin_net_of_priority
      ].min

      @docket_proportions.add_fixed_proportions!(
        legacy: legacy_proportion,
        direct_review: direct_review_proportion
      )
    end

    @docket_proportions
  end

  # Returns how many AMA hearings need to be scheduled in a given time period.
  #
  # Algorithm is as follows:
  #
  #   [   NonPriorityDecisionPerYear = Historical number ]
  #   [ ProportionOfHearingsInDocket = Based off of number of pending appeals in the hearing docket ]
  #
  #   1. Ratio of time period to year:
  #
  #        [     PeriodToYear  = Time in time period / Time in year ]
  #
  #   2. Decisions in next time period:
  #
  #        [ DecisionsInPeriod = PeriodToYear * NonPriorityDecisionPerYear ]
  #
  #   3. Number of appeals to schedule for hearings in next time period:
  #
  #        [      TargetNumber = DecisionInPeriod * ProportionOfHearingsInDocket ]
  #
  def target_number_of_ama_hearings(time_period)
    decisions_in_days = (time_period.to_f / 1.year) * nonpriority_decisions_per_year
    (decisions_in_days * docket_proportions[:hearing]).round
  end

  # Determines which non-priority appeals to schedule for a hearing for a given
  # time period in DAYS.
  #
  # @param time_period [Numeric] The number of days in the time period
  # @param end_of_time_period [Date] The date of last day in the time period
  #
  # @return [ActiveRecord::Relation]
  #   The appeals that should be scheduled in the given time period
  def upcoming_appeals_in_range(time_period, end_of_time_period)
    target = target_number_of_ama_hearings(time_period)

    dockets[:hearing]
      .appeals(priority: false)
      .where(docket_range_date: [nil, end_of_time_period])
      .order("docket_range_date DESC NULLS LAST")
      .limit(target)
  end

  def priority_count
    @priority_count ||= dockets
      .values
      .map { |docket| docket.count(priority: true, ready: true) }
      .sum
  end

  def genpop_priority_count
    @genpop_priority_count ||= dockets.values.map(&:genpop_priority_count).sum
  end

  def direct_review_due_count
    @direct_review_due_count ||= dockets[:direct_review].due_count
  end

  def interpolated_minimum_direct_review_proportion
    return @interpolated_minimum_direct_review_proportion if @interpolated_minimum_direct_review_proportion

    interpolator = 1 - (dockets[:direct_review].time_until_due_of_oldest_appeal.to_f /
                        dockets[:direct_review].time_until_due_of_new_appeal)

    @interpolated_minimum_direct_review_proportion =
      (pacesetting_direct_review_proportion * interpolator * INTERPOLATED_DIRECT_REVIEW_PROPORTION_ADJUSTMENT)
        .clamp(0, MAXIMUM_DIRECT_REVIEW_PROPORTION)
  end

  def pacesetting_direct_review_proportion
    # The pacesetting proportion is the percentage of our nonpriority decision capacity that would need to go
    # to direct reviews in order to keep pace with what is arriving.

    return @pacesetting_direct_review_proportion if @pacesetting_direct_review_proportion

    receipts_per_year = dockets[:direct_review].nonpriority_receipts_per_year

    @pacesetting_direct_review_proportion = receipts_per_year.to_f / nonpriority_decisions_per_year
  end

  def total_batch_size
    JudgeTeam.includes(:non_admin_users).flat_map(&:non_admin_users).size * Distribution::CASES_PER_ATTORNEY
  end

  private

  def docket_margin_net_of_priority
    [total_batch_size - priority_count, 0].max
  end

  def nonpriority_decisions_per_year
    @nonpriority_decisions_per_year ||= [LegacyAppeal, Docket].map(&:nonpriority_decisions_per_year).sum
  end
end
