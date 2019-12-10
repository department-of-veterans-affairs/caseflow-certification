# frozen_string_literal: true

class VirtualHearingMailer < ActionMailer::Base
  default from: "solutions@public.govdelivery.com"
  layout "mailer"
  attr_reader :recipient, :virtual_hearing

  RECIPIENT_TITLES = {
    judge: "Judge",
    veteran: "Veteran",
    representative: "Representative"
  }.freeze

  def cancellation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    mail(to: recipient.email, subject: "Updated location: Your hearing with the Board of Veterans' Appeals")
  end

  def confirmation(mail_recipient:, virtual_hearing: nil, time_changed: false)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    @link = link
    @time_changed = time_changed
    mail(to: recipient.email, subject: confirmation_subject)
  end

  def confirmation_subject
    return "Updated time: Your virtual hearing with the Board of Veterans' Appeals" if @time_changed

    case recipient.title
    when RECIPIENT_TITLES[:veteran], RECIPIENT_TITLES[:veteran]
      "Confirmation: Your virtual hearing with the Board of Veterans' Appeals"
    when RECIPIENT_TITLES[:judge]
      "Confirmation: Your virtual hearing"
    end
  end

  def link
    (recipient.title == RECIPIENT_TITLES[:judge]) ? virtual_hearing.host_link : virtual_hearing.guest_link
  end

  def veteran_full_name
    virtual_hearing.hearing.appeal.veteran.name.to_s
  end
end
