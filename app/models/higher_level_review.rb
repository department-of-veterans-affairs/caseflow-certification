class HigherLevelReview < AmaReview
  with_options if: :saving_review do
    validates :receipt_date, presence: { message: "blank" }
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  private

  def end_product_code
    "030HLRR"
  end

  def end_product_modifiers
    %w[030 031 032 033 033 035 036 037 038 039].freeze
  end
end
