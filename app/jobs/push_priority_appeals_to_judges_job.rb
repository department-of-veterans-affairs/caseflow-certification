# frozen_string_literal: true

# Job that pushes priority cases to a judge rather than waiting for them to request cases. This will distribute cases
# to all judges whose teams that have `accepts_priority_pushed_cases` enabled. The first step distributes all priority
# cases tied to a judge without limit. The second step distributes remaining general population cases (cases not tied to
# an active judge) while attempting to even out the number of priority cases all judges have received over one month
class PushPriorityAppealsToJudgesJob < CaseflowJob
  include AmaCaseDistribution

  def perform
    distribute_non_genpop_priority_appeals
    distribute_genpop_priority_appeals
  end

  # Distribute all priority cases tied to a judge without limit
  def distribute_non_genpop_priority_appeals
    judges_with_tied_priority_cases.each do |judge|
      Distribution.create!(judge: judge, priority_push: true).distribute!
    end
  end

  # Distribute remaining general population cases while attempting to even out the number of priority cases all judges
  # have received over one month
  def distribute_genpop_priority_appeals
    eligible_judge_target_distributions_with_leftovers.each do |judge, target|
      Distribution.create!(judge: judge, priority_push: true).distribute!(target)
    end
  end

  # Find all judges or previous acting judges that have priority cases tied to them
  def judges_with_tied_priority_cases
    User.active.where(css_id: VACOLS::CaseDocket.judge_cssids_tied_to_cases)
  end

  # Give any leftover cases to judges with the lowest distribution targets. Remove judges with 0 cases to be distributed
  # as these are the final counts to distribute remaining ready priority cases
  def eligible_judge_target_distributions_with_leftovers
    leftover_cases = leftover_cases_count
    eligible_judge_target_distributions.sort_by(&:last).map do |judge, target|
      if leftover_cases > 0
        leftover_cases -= 1
        target += 1
      end
      (target > 0) ? [judge, target] : nil
    end.compact.to_h
  end

  # Because we cannot distribute fractional cases, there can be cases leftover after taking the priority target
  # into account. This number will always be less than the number of judges that need distribution because division
  def leftover_cases_count
    ready_priority_appeals_count - eligible_judge_target_distributions.values.sum
  end

  # Calculate the number of cases a judge should receive based on the priority target. Don't toss out judges with 0 as
  # they could receive some of the leftover cases (if any)
  def eligible_judge_target_distributions
    eligible_judge_priority_distributions_this_month.map do |judge, distributions_this_month|
      target = priority_target - distributions_this_month
      (target >= 0) ? [judge, target] : nil
    end.compact.to_h
  end

  # Calculates a target that will distribute all ready appeals so the remaining counts for each judge will produce
  # even case counts over a full month (or as close as we can get to it)
  def priority_target
    @priority_target ||= begin
      distribution_counts = eligible_judge_priority_distributions_this_month.values
      target = (distribution_counts.sum + ready_priority_appeals_count) / distribution_counts.count

      while distribution_counts.any? { |distribution_count| distribution_count > target }
        distribution_counts = distribution_counts.reject { |distribution_count| distribution_count > target }
        target = (distribution_counts.sum + ready_priority_appeals_count) / distribution_counts.count
      end

      target
    end
  end

  def ready_priority_appeals_count
    @ready_priority_appeals_count ||= DocketCoordinator.new.priority_count
  end

  # Number of priority distributions every eligible judge has received in the last month
  def eligible_judge_priority_distributions_this_month
    eligible_judges.map { |judge| [judge, judge_priority_distributions_this_month[judge.id] || 0] }.to_h
  end

  # TODO: Update when kat's toggle has been merged
  def eligible_judges
    @eligible_judges ||= JudgeTeam.available_for_priority_case_distribution.map(&:judge)
  end

  # Produces a hash of judge_id and the number of cases distributed to them in the last month
  def judge_priority_distributions_this_month
    @judge_priority_distributions_this_month ||= priority_distributions_this_month
      .pluck(:judge_id, :statistics)
      .group_by(&:first)
      .map { |judge_id, arr| [judge_id, arr.flat_map(&:last).map { |stats| stats["batch_size"] }.reduce(:+)] }.to_h
  end

  def priority_distributions_this_month
    Distribution.priority_push.completed.where(completed_at: 30.days.ago..Time.zone.now)
  end
end
