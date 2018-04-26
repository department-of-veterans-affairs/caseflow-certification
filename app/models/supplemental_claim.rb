class SupplementalClaim < ApplicationRecord
  include EstablishesEndProduct

  validate :validate_receipt_date
  validates :receipt_date, presence: { message: "blank" }, if: :saving_review

  AMA_BEGIN_DATE = Date.new(2018, 4, 17).freeze

  attr_reader :saving_review

  def start_review!
    @saving_review = true
  end

  private

  # TODO Update with real code and modifier data
  def end_product_code
    "040SCRAMA"
  end

  def end_product_modifier
    "040"
  end

  def end_product_station
    "499" # National Work Queue
  end

  def validate_receipt_date_not_before_ama
    errors.add(:receipt_date, "before_ama") if receipt_date < AMA_BEGIN_DATE
  end

  def validate_receipt_date_not_in_future
    errors.add(:receipt_date, "in_future") if Time.zone.today < receipt_date
  end

  def validate_receipt_date
    return unless receipt_date
    validate_receipt_date_not_before_ama
    validate_receipt_date_not_in_future
  end
end
