# frozen_string_literal: true

class Api::V3::LegacyRelatedIssueSerializer
  include FastJsonapi::ObjectSerializer

  attribute :description, &:friendly_description#&:levels # levels == labels[2..-1] || []
  attribute :program, &:program # program == labels[0]

  # attribute :type, &:type # type == labels[1] # handled in friendly description
  attribute :disposition # @issues ||= AppealSeriesIssues.new(appeal_series: self).all
  attribute :close_date
  attribute :note # are we sure we want to expose this
  attribute(:readjudication) { false } # learn more about this
  attribute :remand_reasons # [{ "code": "AB", "post_aoj": true }]
end
