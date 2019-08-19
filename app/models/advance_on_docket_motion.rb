# frozen_string_literal: true

class AdvanceOnDocketMotion < ApplicationRecord
  belongs_to :person
  belongs_to :user

  enum status: {
    granted: "granted",
    denied: "denied"
  }
  enum reason: {
    financial_distress: "financial_distress",
    age: "age",
    serious_illness: "serious_illness",
    other: "other"
  }

  class << self
    def granted_for_person?(person_id, appeal_receipt_date)
      where(
        granted: true,
        created_at: appeal_receipt_date..DateTime::Infinity.new, 
        person_id: person_id
      ).any?
    end
  end

end
