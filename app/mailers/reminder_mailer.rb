class ReminderMailer < ApplicationMailer
  def rootein_reminder(user, rootein)
    @user = user
    @rootein = rootein
    @name = user.name.presence || user.email_address.split("@").first

    mail to: user.email_address, subject: "Reminder: #{rootein.name}"
  end

  def slacking_alert(user, rootein)
    @user = user
    @rootein = rootein
    @name = user.name.presence || user.email_address.split("@").first
    @days_missed = rootein.current_streak == 0 ? days_since_last_completion(rootein) : 0

    mail to: user.email_address, subject: "You're slacking on #{rootein.name}!"
  end

  private

  def days_since_last_completion(rootein)
    last = rootein.completions.order(completed_on: :desc).first
    last ? (Date.today - last.completed_on).to_i : 999
  end
end
