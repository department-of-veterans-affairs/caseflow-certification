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
  let(:virtual_hearing) { create(:virtual_hearing, hearing: hearing) }
  let(:recipient_title) { nil }
  let(:recipient) { MailRecipient.new(name: "LastName", email: "email@test.com", title: recipient_title) }
  let(:pexip_url) { "fake.va.gov" }

  shared_context "ama_hearing" do
    let(:hearing) do
      create(
        :hearing,
        scheduled_time: "8:30AM",
        hearing_day: hearing_day,
        regional_office: regional_office
      )
    end
  end

  shared_context "legacy_hearing" do
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

  shared_context "cancellation_email" do
    subject { VirtualHearingMailer.cancellation(mail_recipient: recipient, virtual_hearing: virtual_hearing) }
  end

  shared_context "confirmation_email" do
    subject { VirtualHearingMailer.confirmation(mail_recipient: recipient, virtual_hearing: virtual_hearing) }
  end

  shared_context "updated_time_confirmation_email" do
    subject do
      VirtualHearingMailer.updated_time_confirmation(mail_recipient: recipient, virtual_hearing: virtual_hearing)
    end
  end

  before do
    # Freeze the time to when this fix is made to workaround a potential DST bug.
    Timecop.freeze(Time.utc(2020, 1, 20, 16, 50, 0))

    stub_const("ENV", "PEXIP_CLIENT_HOST" => pexip_url)
  end

  context "for judge" do
    include_context "ama_hearing"

    let!(:recipient_title) { MailRecipient::RECIPIENT_TITLES[:judge] }

    describe "#cancellation" do
      include_context "cancellation_email"

      it "doesn't send an email" do
        expect { subject.deliver_now! }.to_not(change { ActionMailer::Base.deliveries.count })
      end
    end

    describe "#confirmation" do
      include_context "confirmation_email"

      it "sends an email" do
        expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
      end
    end

    describe "#updated_time_confirmation" do
      include_context "updated_time_confirmation_email"

      it "sends an email" do
        expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
      end
    end

    # we expect the judge to always see the hearing time in central office (eastern) time zone

    # ama hearing is scheduled at 8:30am in the regional office's time zone
    expected_ama_times = { expected_eastern: "8:30am EST", expected_pacific: "11:30am EST" }
    # legacy hearing is scheduled at 11:30am in the regional office's time zone
    expected_legacy_times = { expected_eastern: "11:30am EST", expected_pacific: "2:30pm EST" }

    ama_times = expected_ama_times
    legacy_times = expected_legacy_times
    types = [:confirmation, :updated_time_confirmation]
    recipient_title = MailRecipient::RECIPIENT_TITLES[:judge]

    types = [:cancellation, :confirmation, :updated_time_confirmation] if types.nil?

    context "with ama hearing" do
      include_context "ama_hearing"

      expected_eastern = ama_times[:expected_eastern]
      expected_pacific = ama_times[:expected_pacific]

      if types.include? :cancellation
        describe "#cancellation" do
          include_context "cancellation_email"

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
      end

      if types.include? :confirmation
        describe "#confirmation" do
          include_context "confirmation_email"

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
      end

      if types.include? :updated_time_confirmation
        describe "#updated_time_confirmation" do
          include_context "updated_time_confirmation_email"

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
      end
    end

    context "with legacy hearing" do
      include_context "legacy_hearing"

      expected_eastern = legacy_times[:expected_eastern]
      expected_pacific = legacy_times[:expected_pacific]

      if types.include? :cancellation
        describe "#cancellation" do
          include_context "cancellation_email"

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
      end

      if types.include? :confirmation
        describe "#confirmation" do
          include_context "confirmation_email"

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
      end

      if types.include? :updated_time_confirmation
        describe "#updated_time_confirmation" do
          include_context "updated_time_confirmation_email"

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
      end
    end

    recipient = MailRecipient::RECIPIENT_TITLES[:judge]

    describe "#confirmation" do
      include_context "confirmation_email"

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

    describe "#updated_time_confirmation" do
      include_context "updated_time_confirmation_email"

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
  end

  context "for appellant" do
    include_context "ama_hearing"

    let!(:recipient_title) { MailRecipient::RECIPIENT_TITLES[:appellant] }

    describe "#cancellation" do
      include_context "cancellation_email"

      it "sends an email" do
        expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
      end
    end

    describe "#confirmation" do
      include_context "confirmation_email"

      it "sends an email" do
        expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
      end
    end

    describe "#updated_time_confirmation" do
      include_context "updated_time_confirmation_email"

      it "sends an email" do
        expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
      end
    end

    # we expect the appellant to always see the hearing time in the regional office time zone
    # unless appellant_tz in VirtualHearing is set

    # ama hearing is scheduled at 8:30am in the regional office's time zone
    expected_ama_times = { expected_eastern: "8:30am EST", expected_pacific: "5:30am PST" }
    # legacy hearing is scheduled at 11:30am in the regional office's time zone
    expected_legacy_times = { expected_eastern: "11:30am EST", expected_pacific: "11:30am PST" }

    ama_times = expected_ama_times
    legacy_times = expected_legacy_times
    types = [:cancellation, :confirmation, :updated_time_confirmation]
    recipient_title = MailRecipient::RECIPIENT_TITLES[:appellant]

    context "with ama hearing" do
      include_context "ama_hearing"

      expected_eastern = ama_times[:expected_eastern]
      expected_pacific = ama_times[:expected_pacific]

      if types.include? :cancellation
        describe "#cancellation" do
          include_context "cancellation_email"

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
      end

      if types.include? :confirmation
        describe "#confirmation" do
          include_context "confirmation_email"

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
      end

      if types.include? :updated_time_confirmation
        describe "#updated_time_confirmation" do
          include_context "updated_time_confirmation_email"

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
      end
    end

    context "with legacy hearing" do
      include_context "legacy_hearing"

      expected_eastern = legacy_times[:expected_eastern]
      expected_pacific = legacy_times[:expected_pacific]

      if types.include? :cancellation
        describe "#cancellation" do
          include_context "cancellation_email"

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
      end

      if types.include? :confirmation
        describe "#confirmation" do
          include_context "confirmation_email"

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
      end

      if types.include? :updated_time_confirmation
        describe "#updated_time_confirmation" do
          include_context "updated_time_confirmation_email"

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
      end
    end


    recipient = MailRecipient::RECIPIENT_TITLES[:appellant]

    describe "#confirmation" do
      include_context "confirmation_email"

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

    describe "#updated_time_confirmation" do
      include_context "updated_time_confirmation_email"

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

    describe "#cancellation" do
      include_context "cancellation_email"

      context "with legacy hearing" do
        include_context "legacy_hearing"

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

      context "with ama hearing" do
        include_context "ama_hearing"

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
    end
  end

  context "for representative" do
    include_context "ama_hearing"

    let!(:recipient_title) { MailRecipient::RECIPIENT_TITLES[:representative] }

    describe "#cancellation" do
      include_context "cancellation_email"

      it "sends an email" do
        expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
      end
    end

    describe "#confirmation" do
      include_context "confirmation_email"

      it "sends an email" do
        expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
      end
    end

    describe "#updated_time_confirmation" do
      include_context "updated_time_confirmation_email"

      it "sends an email" do
        expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
      end
    end

    # we expect the representative to always see the hearing time in the regional office time zone
    # unless representative_tz in VirtualHearing is set

    # ama hearing is scheduled at 8:30am in the regional office's time zone
    expected_ama_times = { expected_eastern: "8:30am EST", expected_pacific: "5:30am PST" }
    # legacy hearing is scheduled at 11:30am in the regional office's time zone
    expected_legacy_times = { expected_eastern: "11:30am EST", expected_pacific: "11:30am PST" }

    ama_times = expected_ama_times
    legacy_times = expected_legacy_times
    types = [:cancellation, :confirmation, :updated_time_confirmation]
    recipient_title = MailRecipient::RECIPIENT_TITLES[:representative]

    context "with ama hearing" do
      include_context "ama_hearing"

      expected_eastern = ama_times[:expected_eastern]
      expected_pacific = ama_times[:expected_pacific]

      if types.include? :cancellation
        describe "#cancellation" do
          include_context "cancellation_email"

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
      end

      if types.include? :confirmation
        describe "#confirmation" do
          include_context "confirmation_email"

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
      end

      if types.include? :updated_time_confirmation
        describe "#updated_time_confirmation" do
          include_context "updated_time_confirmation_email"

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
      end
    end

    context "with legacy hearing" do
      include_context "legacy_hearing"

      expected_eastern = legacy_times[:expected_eastern]
      expected_pacific = legacy_times[:expected_pacific]

      if types.include? :cancellation
        describe "#cancellation" do
          include_context "cancellation_email"

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
      end

      if types.include? :confirmation
        describe "#confirmation" do
          include_context "confirmation_email"

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
      end

      if types.include? :updated_time_confirmation
        describe "#updated_time_confirmation" do
          include_context "updated_time_confirmation_email"

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
      end
    end


    recipient = MailRecipient::RECIPIENT_TITLES[:representative]

    describe "#confirmation" do
      include_context "confirmation_email"

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

    describe "#updated_time_confirmation" do
      include_context "updated_time_confirmation_email"

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

    describe "#cancellation" do
      include_context "cancellation_email"

      context "with legacy hearing" do
        include_context "legacy_hearing"

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

      context "with ama hearing" do
        include_context "ama_hearing"

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
    end
  end
end
