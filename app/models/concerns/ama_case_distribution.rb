module AmaCaseDistribution
  extend ActiveSupport::Concern

  private

  def ama_distribution
    @appeals = []
    @rem = batch_size
    @remaining_docket_proportions = docket_proportions.clone
    @nonpriority_iterations = 0

    # Count the number of priority appeals available before we distribute anything.
    priority_count

    # Distribute priority appeals that are tied to judges (not genpop).
    distribute_appeals(:legacy, @rem, priority: true, genpop: "not_genpop")
    distribute_appeals(:hearing, @rem, priority: true, genpop: "not_genpop")

    # Distribute nonpriority appeals that are tied to judges.
    # Legacy docket appeals that are tied to judges are only distributed when they are within the docket range.
    distribute_appeals(:legacy, @rem, priority: false, genpop: "not_genpop", range: legacy_docket_range)
    distribute_appeals(:hearing, @rem, priority: false, genpop: "not_genpop")

    # If we haven't yet met the priority target, distribute additional priority appeals.
    priority_rem = (priority_target - @appeals.count(&:priority)).clamp(0, @rem)
    oldest_priority_appeals_by_docket(priority_rem).each do |docket, n|
      distribute_appeals(docket, n, priority: true)
    end

    # As we may have already distributed nonpriority legacy and hearing docket cases, we adjust the docket proportions.
    deduct_distributed_actuals_from_remaining_docket_proportions(:legacy, :hearing)

    # Distribute nonpriority appeals from any docket according to the docket proportions.
    # If a docket runs out of available appeals, we reallocate its cases to the other dockets.
    until @rem == 0 || @remaining_docket_proportions.all_zero?
      distribute_appeals_according_to_remaining_docket_proportions
      @nonpriority_iterations += 1
    end

    @appeals
  end

  def ama_statistics
    {
      batch_size: batch_size,
      total_batch_size: total_batch_size,
      priority_count: priority_count,
      legacy_proportion: docket_proportions[:legacy],
      direct_review_proportion: docket_proportions[:direct_review],
      evidence_submission_proportion: docket_proportions[:evidence_submission],
      hearing_proportion: docket_proportions[:hearing],
      nonpriority_iterations: @nonpriority_iterations
    }
  end

  def distribute_appeals(docket, n, priority: false, genpop: "any", range: nil)
    return [] unless n > 0

    if range.nil?
      appeals = dockets[docket].distribute_appeals(self, priority: priority, genpop: genpop, limit: n)
    elsif docket == :legacy && priority == false
      return [] unless range > 0
      appeals = dockets[:legacy].distribute_nonpriority_appeals(self, genpop: genpop, range: range, limit: n)
    else
      return
    end

    @appeals += appeals
    @rem -= appeals.count

    appeals
  end

  def deduct_distributed_actuals_from_remaining_docket_proportions(*args)
    nonpriority_target = batch_size - @appeals.count(&:priority)

    return if nonpriority_target == 0

    args.each do |docket|
      docket_count = @appeals.count { |appeal| appeal.docket == docket.to_s && !appeal.priority }
      proportion = docket_count / nonpriority_target
      @remaining_docket_proportions[docket] = [@remaining_docket_proportions[docket] - proportion, 0].max
    end
  end

  def distribute_appeals_according_to_remaining_docket_proportions
    @remaining_docket_proportions
      .normalize!
      .stochastic_allocation(@rem)
      .each do |docket, n|
        appeals = distribute_appeals(docket, n, priority: false)
        @remaining_docket_proportions[docket] = 0 if appeals.count < n
      end
  end

  def dockets
    @dockets ||= {
      legacy: LegacyDocket.new,
      direct_review: AmaDirectReviewDocket.new,
      evidence_submission: AmaEvidenceSubmissionDocket.new,
      hearing: AmaHearingDocket.new
    }
  end

  def priority_count
    @priority_count ||= dockets
      .values
      .map { |docket| docket.count(priority: true, ready: true) }
      .reduce(0, :+)
  end

  def priority_target
    proportion = [priority_count.to_f / total_batch_size, 1].min
    (proportion * batch_size).ceil
  end

  def legacy_docket_range
    [(total_batch_size - priority_count) * docket_proportions[:legacy], 0].max.round
  end

  def oldest_priority_appeals_by_docket(n)
    return {} unless n > 0

    dockets
      .map { |sym, docket| docket.age_of_n_oldest_priority_appeals(n).map { |age| [age, sym] } }
      .flatten
      .sort_by { |a| a[0] }
      .first(n)
      .each_with_object(Hash.new(0)) { |a, counts| counts[a[1]] += 1 }
  end

  # CMGTODO
  def docket_proportions
    @docket_proportions ||= dockets.transform_values(&:weight).extend(ProportionHash).normalize!
  end
end

module ProportionHash
  def normalize!
    total = values.reduce(0, :+)
    transform_values! { |proportion| proportion * (1.0 / total) }
  end

  def stochastic_allocation(n)
    result = transform_values { |proportion| (n * proportion).floor }
    rem = n - result.values.reduce(0, :+)

    return result if rem == 0

    iterations = rem

    catch :complete do
      each_with_index do |(key, proportion), i|
        if i == count - 1
          result[key] += rem
          throw :complete
        end

        probability = (n * proportion).modulo(1) / iterations

        iterations.times do
          next unless probability > rand

          result[key] += 1
          rem -= 1

          throw :complete if rem == 0
        end
      end
    end

    result
  end

  def all_zero?
    all? { |_, proportion| proportion == 0 }
  end
end
