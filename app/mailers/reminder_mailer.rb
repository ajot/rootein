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
    @days_missed = rootein.current_streak == 0 ? rootein.days_since_last_completion : 0

    mail to: user.email_address, subject: "You're slacking on #{rootein.name}!"
  end

end
