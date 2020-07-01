# frozen_string_literal: true

describe VirtualHearingMailer do
  let(:nyc_ro_eastern) { "RO06" }
  let(:oakland_ro_pacific) { "RO43" }
  let(:regional_office) { nyc_ro_eastern }
  let(:hearing_day) do
    create(
      :hearing_day,
      request_type: HearingDay::REQUEST_TYPES[:video],
      regional_office: regional_office
    )
  end
  let(:virtual_hearing) do
    create(
      :virtual_hearing,
      hearing: hearing
    )
  end

  let(:recipient_title) { nil }
  let(:recipient) { MailRecipient.new(name: "LastName", email: "email@test.com", title: recipient_title) }
  let(:pexip_url) { "fake.va.gov" }

  shared_context "ama hearing" do
    let(:hearing) do
      create(
        :hearing,
        scheduled_time: "8:30AM",
        hearing_day: hearing_day,
        regional_office: regional_office
      )
    end
  end

  shared_context "legacy hearing" do
    let(:hearing) do
      hearing_date = Time.use_zone("America/New_York") { Time.zone.now.change(hour: 11, min: 30) }
      case_hearing = create(
        :case_hearing,
        hearing_type: hearing_day.request_type,
        hearing_date: VacolsHelper.format_datetime_with_utc_timezone(hearing_date) # VACOLS always has EST time
      )
      hearing_location = create(:hearing_location, regional_office: regional_office)

      create(
        :legacy_hearing,
        case_hearing: case_hearing,
        hearing_day_id: hearing_day.id,
        hearing_location: hearing_location
      )
    end
  end

  shared_context "cancellation email" do
    subject { VirtualHearingMailer.cancellation(mail_recipient: recipient, virtual_hearing: virtual_hearing) }
  end

  shared_context "confirmation email" do
    subject { VirtualHearingMailer.confirmation(mail_recipient: recipient, virtual_hearing: virtual_hearing) }
  end

  shared_context "updated time confirmation email" do
    subject do
      VirtualHearingMailer.updated_time_confirmation(mail_recipient: recipient, virtual_hearing: virtual_hearing)
    end
  end

  before do
    # Freeze the time to when this fix is made to workaround a potential DST bug.
    Timecop.freeze(Time.utc(2020, 1, 20, 16, 50, 0))

    stub_const("ENV", "PEXIP_CLIENT_HOST" => pexip_url)
  end

  shared_examples_for "sends an email" do
    it "sends an email" do
      expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
    end
  end

  shared_examples_for "doesn't send an email" do
    it "doesn't send an email" do
      expect { subject.deliver_now! }.to_not(change { ActionMailer::Base.deliveries.count })
    end
  end

  shared_examples_for "doesn't send a cancellation email" do
    describe "#cancellation" do
      include_context "cancellation email"

      it_behaves_like "doesn't send an email"
    end
  end

  shared_examples_for "sends a cancellation email" do
    describe "#cancellation" do
      include_context "cancellation email"

      it_behaves_like "sends an email"
    end
  end

  shared_examples_for "sends a confirmation email" do
    describe "#confirmation" do
      include_context "confirmation email"

      it_behaves_like "sends an email"
    end
  end

  shared_examples_for "sends an updated time confirmation email" do
    describe "#updated_time_confirmation" do
      include_context "updated time confirmation email"

      it_behaves_like "sends an email"
    end
  end

  shared_examples_for "sends all email types" do
    it_behaves_like "sends a cancellation email"
    it_behaves_like "sends a confirmation email"
    it_behaves_like "sends an updated time confirmation email"
  end

  shared_examples_for "email body has the right times based on regional_office" do
    |expected_eastern, expected_pacific, recipient_title|
    context "regional office is in eastern timezone" do
      let(:regional_office) { nyc_ro_eastern }

      it "has the correct time in the email" do
        expect(subject.html_part.body).to include(expected_eastern)
      end
    end

    context "regional office is in pacific timezone" do
      let(:regional_office) { oakland_ro_pacific }

      it "has the correct time in the email" do
        if recipient_title == MailRecipient::RECIPIENT_TITLES[:judge]
          # judge time in the email will always be in central office time (ET)
          expect(subject.html_part.body).to include(expected_pacific)
        else
          # always show regional office time regardless of recipient
          expect(subject.html_part.body).to include("8:30am PST")
        end
      end
    end
  end

  shared_examples_for "email body has right time for recipient" do |expected_eastern, expected_pacific, recipient_title|
    if recipient_title == MailRecipient::RECIPIENT_TITLES[:judge]
      it "displays central office time (ET)" do
        expect(subject.html_part.body).to include(expected_eastern)
      end
    elsif recipient_title == MailRecipient::RECIPIENT_TITLES[:appellant]
      describe "appellant_tz is present" do
        before do
          virtual_hearing.update!(appellant_tz: "America/Los_Angeles")
          hearing.reload
        end

        it "displays pacific standard time (PT)" do
          expect(subject.html_part.body).to include(expected_pacific)
        end
      end

      describe "appellant_tz is not present" do
        it "displays eastern standard time (ET)" do
          expect(subject.html_part.body).to include(expected_eastern)
        end
      end
    elsif recipient_title == MailRecipient::RECIPIENT_TITLES[:representative]
      describe "representative_tz is present" do
        before do
          virtual_hearing.update!(representative_tz: "America/Los_Angeles")
          hearing.reload
        end

        it "displays pacific standard time (PT)" do
          expect(subject.html_part.body).to include(expected_pacific)
        end
      end

      describe "representative_tz is not present" do
        it "displays eastern standard time (ET)" do
          expect(subject.html_part.body).to include(expected_eastern)
        end
      end
    end
  end

  shared_examples_for "email body has the right times for types" do
    |expected_eastern, expected_pacific, types, recipient_title|
    if types.include? :cancellation
      describe "#cancellation" do
        include_context "cancellation email"

        it_behaves_like(
          "email body has the right times based on regional_office",
          expected_eastern,
          expected_pacific,
          recipient_title
        )
        it_behaves_like "email body has right time for recipient", expected_eastern, expected_pacific, recipient_title
      end
    end

    if types.include? :confirmation
      describe "#confirmation" do
        include_context "confirmation email"

        it_behaves_like(
          "email body has the right times based on regional_office",
          expected_eastern,
          expected_pacific,
          recipient_title
        )
        it_behaves_like "email body has right time for recipient", expected_eastern, expected_pacific, recipient_title
      end
    end

    if types.include? :updated_time_confirmation
      describe "#updated_time_confirmation" do
        include_context "updated time confirmation email"

        it_behaves_like(
          "email body has the right times based on regional_office",
          expected_eastern,
          expected_pacific,
          recipient_title
        )
        it_behaves_like "email body has right time for recipient", expected_eastern, expected_pacific, recipient_title
      end
    end
  end

  # ama_times & legacy_times are in the format { expected_eastern: "10:30 EST", expected_pacific: "7:30 PST" }
  # expected_eastern is the time displayed in the email body when the regional office is in the eastern time zone
  # expected_pacific is the time displayed in the email body when the regional office is in the pacific time zone
  shared_examples_for "email body has the right times with ama and legacy hearings" do
    |ama_times, legacy_times, types, recipient_title|
    types = [:cancellation, :confirmation, :updated_time_confirmation] if types.nil?

    context "with ama hearing" do
      include_context "ama hearing"

      it_behaves_like(
        "email body has the right times for types",
        ama_times[:expected_eastern],
        ama_times[:expected_pacific],
        types,
        recipient_title
      )
    end

    context "with legacy hearing" do
      include_context "legacy hearing"

      it_behaves_like(
        "email body has the right times for types",
        legacy_times[:expected_eastern],
        legacy_times[:expected_pacific],
        types,
        recipient_title
      )
    end
  end

  shared_examples_for "email body has the correct link" do |recipient|
    if recipient == MailRecipient::RECIPIENT_TITLES[:judge]
      describe "#link" do
        it "is host link" do
          expect(subject.html_part.body).to include(virtual_hearing.host_link)
        end

        it "is in correct format" do
          expect(virtual_hearing.host_link).to eq(
            "#{VirtualHearing.base_url}?join=1&media=&escalate=1&" \
            "conference=#{virtual_hearing.formatted_alias_or_alias_with_host}&" \
            "pin=#{virtual_hearing.host_pin}&role=host"
          )
        end
      end
    end

    if recipient == MailRecipient::RECIPIENT_TITLES[:appellant] ||
       recipient == MailRecipient::RECIPIENT_TITLES[:representative]
      it "has the test link" do
        expect(subject.html_part.body).to include(virtual_hearing.test_link(recipient))
      end

      describe "#link" do
        it "is guest link" do
          expect(subject.html_part.body).to include(virtual_hearing.guest_link)
        end

        it "is in correct format" do
          expect(virtual_hearing.guest_link).to eq(
            "#{VirtualHearing.base_url}?join=1&media=&escalate=1&" \
            "conference=#{virtual_hearing.formatted_alias_or_alias_with_host}&" \
            "pin=#{virtual_hearing.guest_pin}&role=guest"
          )
        end
      end
    end
  end

  shared_examples_for "email body has the correct link for types" do |recipient|
    describe "#confirmation" do
      include_context "confirmation email"

      it_behaves_like "email body has the correct link", recipient
    end

    describe "#updated_time_confirmation" do
      include_context "updated time confirmation email"

      it_behaves_like "email body has the correct link", recipient
    end
  end

  shared_examples_for "email body has correct hearing location" do
    describe "hearing_location is not nil" do
      it "shows correct hearing location" do
        expect(subject.html_part.body).to include(hearing.location.full_address)
        expect(subject.html_part.body).to include(hearing.hearing_location.name)
      end
    end

    describe "hearing_location is nil" do
      it "shows correct hearing location" do
        hearing.update!(hearing_location: nil)
        expect(subject.html_part.body).to include(hearing.regional_office.full_address)
        expect(subject.html_part.body).to include(hearing.regional_office.name)
      end
    end
  end

  shared_examples_for "cancellation email body has the correct hearing location" do
    describe "#cancellation" do
      include_context "cancellation email"

      context "with legacy hearing" do
        include_context "legacy hearing"

        it_behaves_like "email body has correct hearing location"
      end

      context "with ama hearing" do
        include_context "ama hearing"

        it_behaves_like "email body has correct hearing location"
      end
    end
  end

  context "for judge" do
    include_context "ama hearing"

    let!(:recipient_title) { MailRecipient::RECIPIENT_TITLES[:judge] }

    it_behaves_like "doesn't send a cancellation email"
    it_behaves_like "sends a confirmation email"
    it_behaves_like "sends an updated time confirmation email"

    # we expect the judge to always see the hearing time in central office (eastern) time zone

    # ama hearing is scheduled at 8:30am in the regional office's time zone
    expected_ama_times = {
      expected_eastern: "8:30am EST",
      expected_pacific: "11:30am EST"
    }
    # legacy hearing is scheduled at 11:30am in the central office's time zone (eastern)
    expected_legacy_times = { expected_eastern: "11:30am EST", expected_pacific: "2:30pm EST" }
    it_behaves_like(
      "email body has the right times with ama and legacy hearings",
      expected_ama_times,
      expected_legacy_times,
      [:confirmation, :updated_time_confirmation],
      MailRecipient::RECIPIENT_TITLES[:judge]
    )
    it_behaves_like("email body has the correct link for types", MailRecipient::RECIPIENT_TITLES[:judge])
  end

  context "for appellant" do
    include_context "ama hearing"

    let!(:recipient_title) { MailRecipient::RECIPIENT_TITLES[:appellant] }

    it_behaves_like "sends all email types"

    # we expect the appellant to always see the hearing time in the regional office time zone
    # unless appellant_tz in VirtualHearing is set

    # ama hearing is scheduled at 8:30am in the regional office's time zone
    expected_ama_times = { expected_eastern: "8:30am EST", expected_pacific: "5:30am PST" }
    # legacy hearing is scheduled at 11:30am in the central office's time zone (eastern)
    expected_legacy_times = { expected_eastern: "11:30am EST", expected_pacific: "11:30am PST" }
    it_behaves_like(
      "email body has the right times with ama and legacy hearings",
      expected_ama_times,
      expected_legacy_times,
      nil,
      MailRecipient::RECIPIENT_TITLES[:appellant]
    )

    it_behaves_like("email body has the correct link for types", MailRecipient::RECIPIENT_TITLES[:appellant])
    it_behaves_like("cancellation email body has the correct hearing location")
  end

  context "for representative" do
    include_context "ama hearing"

    let!(:recipient_title) { MailRecipient::RECIPIENT_TITLES[:representative] }

    it_behaves_like "sends all email types"

    # we expect the representative to always see the hearing time in the regional office time zone
    # unless representative_tz in VirtualHearing is set

    # ama hearing is scheduled at 8:30am in the regional office's time zone
    expected_ama_times = { expected_eastern: "8:30am EST", expected_pacific: "5:30am PST" }
    # legacy hearing is scheduled at 11:30am in the central office's time zone (eastern)
    expected_legacy_times = { expected_eastern: "11:30am EST", expected_pacific: "11:30am PST" }
    expected_legacy_times = { expected_eastern: "11:30am EST", expected_pacific: "8:30am PST" }

    it_behaves_like(
      "email body has the right times with ama and legacy hearings",
      expected_ama_times,
      expected_legacy_times,
      nil,
      MailRecipient::RECIPIENT_TITLES[:representative]
    )
    it_behaves_like("email body has the correct link for types", MailRecipient::RECIPIENT_TITLES[:representative])
    it_behaves_like("cancellation email body has the correct hearing location")
  end
end
