# frozen_string_literal: true

# abstract base class for all ETL:: models

# "original" == Caseflow db record
# "target" == ETL db record
#
# Note about schema Rails automatic meta columns:
#  * if the table is a 1:1 mirror:
#    * the "id" is the same in original and target
#    * the "created_at" and "updated_at" are the same on original and target
#  * if the table is transformed in any way:
#    * the "id" of the original is mapped to ":original_id" (e.g. appeal_id)
#    * the "created_at" may be the same on original and target, if not, there is a ":original_created_at"
#    * the "updated_at" should be modified every time target (ETL) is modified

class ETL::Record < ApplicationRecord
  self.abstract_class = true
  establish_connection :"etl_#{Rails.env}"

  class << self
    def sync_with_original(original)
      target = find_by_primary_key(original) || new
      merge_original_attributes_to_target(original, target)
    end

    # the column on this class that refers to the origin class primary key
    # the default assumption is that the 2 classes share a primary key name (e.g. "id")
    def origin_primary_key
      primary_key
    end

    private

    def merge_original_attributes_to_target(original, target)
      target.attributes = original.attributes
      target
    end

    def find_by_primary_key(original)
      pk = original[original.class.primary_key]
      find_by(origin_primary_key => pk)
    end
  end
end
