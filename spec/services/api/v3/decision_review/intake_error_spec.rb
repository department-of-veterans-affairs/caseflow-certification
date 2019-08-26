# frozen_string_literal: true

require "rails_helper"

context Api::V3::DecisionReview::IntakeError do
  context "::KNOWN_ERRORS" do
    subject { Api::V3::DecisionReview::IntakeError::KNOWN_ERRORS }
    it "should be an array" do
      expect(subject).to be_kind_of(Array)
    end
    it "should be non-empty" do
      expect(subject.length).to be > 0
    end
  end

  context "::UNKNOWN_ERROR" do
    subject { Api::V3::DecisionReview::IntakeError::UNKNOWN_ERROR }
    it "should be an array" do
      expect(subject).to be_kind_of(Array)
    end
    it "should be non-empty" do
      expect(subject.length).to be > 0
    end
  end

  context "::KNOWN_ERRORS_BY_CODE" do
    subject { Api::V3::DecisionReview::IntakeError::KNOWN_ERRORS_BY_CODE }
    it "should be a hash" do
      expect(subject).to be_kind_of(Hash)
    end
    it "should be non-empty" do
      expect(subject.keys.length).to be > 0
    end
  end

  context ".error_code" do
    it ":hello should return :hello" do
      expect(Api::V3::DecisionReview::IntakeError.error_code(:hello)).to eq(:hello)
    end
    it "\"hello\" should return :hello" do
      expect(Api::V3::DecisionReview::IntakeError.error_code("hello")).to eq(:hello)
    end
    it "26 should return nil" do
      expect(Api::V3::DecisionReview::IntakeError.error_code(26)).to eq(nil)
    end
    klass = Struct.new(:error_code)
    obj_with_string_error_code = klass.new("dog")
    it "obj should return :dog" do
      expect(Api::V3::DecisionReview::IntakeError.error_code(obj_with_string_error_code)).to eq(:dog)
    end
    obj_with_false_error_code = klass.new(false)
    it "obj should return nil" do
      expect(Api::V3::DecisionReview::IntakeError.error_code(obj_with_false_error_code)).to eq(nil)
    end
    nested_obj = klass.new(klass.new(klass.new(:russian_doll)))
    it "obj should return :russian_doll" do
      expect(Api::V3::DecisionReview::IntakeError.error_code(nested_obj)).to eq(:russian_doll)
    end
  end

  context ".find_first_error_code" do
    obj = Struct.new(:error_code).new("cat")
    it "should return :hello" do
      expect(
        Api::V3::DecisionReview::IntakeError.find_first_error_code([:hello, obj])
      ).to eq(:hello)
    end
    it "should return #{obj.error_code}" do
      expect(
        Api::V3::DecisionReview::IntakeError.find_first_error_code([777, obj])
      ).to eq(obj.error_code.to_sym)
    end
    it "should return nil" do
      expect(
        Api::V3::DecisionReview::IntakeError.find_first_error_code([nil, false])
      ).to eq(nil)
    end
  end

  context ".new" do
    obj_with_invalid_code = Struct.new(:error_code).new("cat")
    obj_with_valid_code = Struct.new(:error_code).new("intake_start_failed")
    it "should be unknown" do
      expect(
        Api::V3::DecisionReview::IntakeError.new(obj_with_invalid_code).as_json.values_at("status", "code", "title")
      ).to eq(Api::V3::DecisionReview::IntakeError::UNKNOWN_ERROR.as_json)
    end
    it "should not raise" do
      expect do
        Api::V3::DecisionReview::IntakeError.new(obj_with_valid_code)
      end.not_to raise_error
    end
  end

  context ".from_first_error_code_found" do
    obj_a = Struct.new(:error_code).new("dog")
    obj_b = Struct.new(:error_code).new("intake_review_failed")
    it "should be unknown" do
      expect(
        Api::V3::DecisionReview::IntakeError.from_first_error_code_found([obj_a, obj_b]).code
      ).to eq(:unknown_error)
    end
    it "should be :intake_review_failed" do
      expect(
        Api::V3::DecisionReview::IntakeError.from_first_error_code_found([obj_b, obj_a]).code
      ).to eq(:intake_review_failed)
    end
    it "should be :intake_review_failed" do
      expect(
        Api::V3::DecisionReview::IntakeError.from_first_error_code_found([nil, obj_b]).code
      ).to eq(:intake_review_failed)
    end
  end
end
