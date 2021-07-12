# frozen_string_literal: true

class Api::V3::LegacyIssueSerializer
  include FastJsonapi::ObjectSerializer

  attribute :description, &:friendly_description#&:levels # levels == labels[2..-1] || []
  attribute :program, &:program # program == labels[0]
  # attribute :type, &:type # type == labels[1] # handled in friendly description
  attribute :disposition
  attribute :close_date
  attribute :note
  attribute(:readjudication) { false } # learn more about this
  attribute :remand_reasons
end
