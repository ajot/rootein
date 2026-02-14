# Preview all emails at http://localhost:3000/rails/mailers/reminder_mailer
class ReminderMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/reminder_mailer/rootein_reminder
  def rootein_reminder
    user = User.first
    rootein = user.rooteins.first
    ReminderMailer.rootein_reminder(user, rootein)
  end

  # Preview this email at http://localhost:3000/rails/mailers/reminder_mailer/slacking_alert
  def slacking_alert
    user = User.first
    rootein = user.rooteins.first
    ReminderMailer.slacking_alert(user, rootein)
  end
end
