# frozen_string_literal: true

class QueueFilterParameter
  include ActiveModel::Model

  validates :column, presence: true
  validate :values_is_array

  attr_accessor :column, :values

  def initialize(args)
    super
    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  def self.from_string(filter_string)
    # Transform the filter from a string to a hash and create an object from that hash.
    # "col=docketNumberColumn&val=legacy,evidence_submission"
    # ->
    # { "col": "docketNumberColumn", "val": ["legacy", "evidence_submission"] }
    filter_hash = Rack::Utils.parse_query(filter_string)

    # TODO: Double encode values going to the front-end
    new(column: filter_hash["col"], values: filter_hash["val"]&.split(",")&.map { |val| CGI.unescape(val) })
  end

  private

  def values_is_array
    errors.add(:values, "must be an array") unless values&.is_a?(Array)
  end
end
