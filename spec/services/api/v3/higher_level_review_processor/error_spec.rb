# frozen_string_literal: true

require "rails_helper"

describe Api::V3::HigherLevelReviewProcessor::Error do
  context "::Error" do
    subject { Api::V3::HigherLevelReviewProcessor::Error::Error }
    it("is a Class") { expect(subject).to be_a(Class) }
    it("can set/get status") do
      status = 99
      error = subject.new
      expect(error.status).to be(nil)
      error.status = status
      expect(error.status).to be(status)
    end
    it("can set/get code") do
      code = 23
      error = subject.new
      expect(error.code).to be(nil)
      error.code = code
      expect(error.code).to be(code)
    end
    it("can set/get title") do
      error = subject.new
      title = 78
      expect(error.title).to be(nil)
      error.title = title
      expect(error.title).to be(title)
    end
    it("has the argument order: status-code-title") do
      error = subject.new :a, :b, :c
      expect(error.status).to be(:a)
      expect(error.code).to be(:b)
      expect(error.title).to be(:c)
    end
    it("can become json and only has the keys: status, title, code") do
      expect(subject.new("x", "y", "z").as_json).to eq("status" => "x", "code" => "y", "title" => "z")
    end
  end

  context "::BY_CODE" do
    subject { Api::V3::HigherLevelReviewProcessor::Error::BY_CODE }
    it("is a hash") { expect(subject).to be_a(Hash) }
    it("isn't empty") { expect(subject.empty?).to be(false) }
    it("has only symbols as keys") do
      subject.keys.each do |k|
        expect(k).to be_a(Symbol)
      end
    end
    # number_of_keys = 22
    # it("has #{number_of_keys} keys") { expect(subject.length).to be(number_of_keys) }
    it("has only Errors as values") do
      subject.values.each do |v|
        expect(v).to be_a(Api::V3::HigherLevelReviewProcessor::Error::Error)
      end
    end
    it("each error has an integer status") do
      subject.values.each do |v|
        expect(v.status).to be_a(Integer)
      end
    end
    it("each error has a symbol code") do
      subject.values.each do |v|
        expect(v.code).to be_a(Symbol)
      end
    end
    it("each error has a non-blank string title") do
      subject.values.each do |v|
        expect(v.title).to be_a(String)
        expect(v.title.blank?).to be(false)
      end
    end
  end

  context "::FOR_UNKNOWN_CODE" do
    error = Api::V3::HigherLevelReviewProcessor::Error::Error
    subject { Api::V3::HigherLevelReviewProcessor::Error::FOR_UNKNOWN_CODE }
    it("is an Error") { expect(subject).to be_a(error) }
    it("has an integer status") do
      expect(subject.status).to be_a(Integer)
    end
    it("has a symbol code") do
      expect(subject.code).to be_a(Symbol)
    end
    it("has a non-blank string title") do
      expect(subject.title).to be_a(String)
      expect(subject.title.blank?).to be(false)
    end
  end

  context ".from_error_code" do
    errors_by_code = Api::V3::HigherLevelReviewProcessor::Error::BY_CODE
    error_for_unknown_code = Api::V3::HigherLevelReviewProcessor::Error::FOR_UNKNOWN_CODE
    error = Api::V3::HigherLevelReviewProcessor::Error::Error
    subject { Api::V3::HigherLevelReviewProcessor.new(params, user) }
    it("returns the default error for unknown codes") do
      [false, nil, "", "    ", [], {}, [2], { a: 1 }, :unknown_error].each do |v|
        expect(Api::V3::HigherLevelReviewProcessor::Error.from_error_code(v)).to be(error_for_unknown_code)
      end
    end
    it("returns the correct error") do
      [:request_issue_cannot_be_empty, "request_issue_cannot_be_empty"].each do |v|
        expect(Api::V3::HigherLevelReviewProcessor::Error.from_error_code(v)).to(
          eq(errors_by_code[:request_issue_cannot_be_empty])
        )
      end
      expect(Api::V3::HigherLevelReviewProcessor::Error.from_error_code(:duplicate_intake_in_progress)).to eq(
        error.new(409, :duplicate_intake_in_progress, "Intake in progress")
      )
    end
  end

  context "::StartError" do
    subject { Api::V3::HigherLevelReviewProcessor::Error::StartError }
    it("returns the error_code of intake if it's truthy") do
      intake = Intake.new
      code = "banana"
      intake.error_code = code
      start_error = subject.new(intake)
      expect(start_error.error_code).to eq(code)
    end
    it("returns :intake_start_failed if passed in error_code is falsey") do
      intake = Intake.new
      expect(intake.error_code).to be_nil
      start_error = subject.new(intake)
      expect(start_error.error_code).to be(:intake_start_failed)
    end
  end

  context "::ReviewError" do
    subject { Api::V3::HigherLevelReviewProcessor::Error::ReviewError }
    it("returns the error_code of intake if it's truthy") do
      intake = Intake.new
      code = "banana"
      intake.error_code = code
      review_error = subject.new(intake)
      expect(review_error.error_code).to eq(code)
    end
    it("returns :intake_review_failed if passed in error_code is falsey") do
      intake = Intake.new
      expect(intake.error_code).to be_nil
      review_error = subject.new(intake)
      expect(review_error.error_code).to be(:intake_review_failed)
    end
    it("adds intake.detail's full error messages to ReviewError instance's message") do
      intake = Intake.new
      intake.detail = HigherLevelReview.new
      intake.detail.errors.add :id
      review_error = subject.new(intake)
      expect(review_error.message).to eq(
        "intake.review!(review_params) did not throw an exception, but did return a falsey value:\nId is invalid"
      )
    end
  end
end
