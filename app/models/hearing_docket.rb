# A HearingDocket is a grouping of hearings by a date, type and regional_office_key
class HearingDocket
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :date, :type, :venue, :hearings

  def to_hash
    serializable_hash(
      include: [:hearings],
      methods: [:venue]
    )
  end

  def attributes
    {
      date: date,
      type: type
    }
  end

  class << self
    def for_judge(user)
      Appeal.repository
            .hearings(user.vacols_id)
            .group_by { |h| h.date.to_i }
            .map do |_date, hearings|
        new(
          date: hearings.first.date,
          type: hearings.first.type,
          venue: hearings.first.venue,
          hearings: hearings
        )
      end
    end
  end
end
