# frozen_string_literal: true

class VirtualHearings::SendEmail
  attr_reader :virtual_hearing, :type

  def initialize(virtual_hearing:, type:)
    @virtual_hearing = virtual_hearing
    @type = type
  end

  def call
    if !virtual_hearing.veteran_email_sent
      send_email(:veteran)

      Rails.logger.info("Sent #{type} email to veteran!")

      virtual_hearing.veteran_email_sent = true
    end

    if !virtual_hearing.judge_email.nil? && !virtual_hearing.judge_email_sent
      send_email(:judge)

      Rails.logger.info("Sent #{type} email to judge!")

      virtual_hearing.judge_email_sent = true
    end

    if !virtual_hearing.representative_email.nil? && !virtual_hearing.representative_email_sent
      send_email(:representative)

      Rails.logger.info("Sent #{type} email to representative!")

      virtual_hearing.representative_email_sent = true
    end

    virtual_hearing.save!
  end

  def send_email(recipient)
    if type == :confirmation
      VirtualHearingMailer.confirmation(
        mail_recipient: mail_recipients[recipient],
        virtual_hearing: virtual_hearing
      ).deliver_now
    elsif type == :cancellation
      VirtualHearingMailer.cancellation(
        mail_recipient: mail_recipients[recipient],
        virtual_hearing: virtual_hearing
      ).deliver_now
    elsif type == :updated_time_confirmation
      VirtualHearingMailer.updated_time_confirmation(
        mail_recipient: mail_recipients[recipient],
        virtual_hearing: virtual_hearing
      ).deliver_now
    else
      fail ArgumentError, "Invalid type of email to send: `#{type}`"
    end
  end

  def mail_recipients
    {
      veteran: MailRecipient.new(
        name: virtual_hearing.hearing.appeal.veteran&.first_name,
        email: virtual_hearing.veteran_email,
        title: MailRecipient::RECIPIENT_TITLES[:veteran]
      ),
      judge: MailRecipient.new(
        name: virtual_hearing.hearing.judge&.full_name,
        email: virtual_hearing.judge_email,
        title: MailRecipient::RECIPIENT_TITLES[:judge]
      ),
      representative: MailRecipient.new(
        name: virtual_hearing.hearing.appeal.representative_name,
        email: virtual_hearing.representative_email,
        title: MailRecipient::RECIPIENT_TITLES[:representative]
      )
    }
  end
end
