class SendRemindersJob < ApplicationJob
  queue_as :default

  def perform
    User.where(notification_email: true).find_each do |user|
      user.rooteins.active.each do |rootein|
        # Daily reminder for rooteins with a reminder_time set
        if rootein.reminder_time.present?
          ReminderMailer.rootein_reminder(user, rootein).deliver_later
        end

        # Slacking alert for 3+ days missed
        if rootein.current_streak == 0 && rootein.days_since_last_completion >= 3
          ReminderMailer.slacking_alert(user, rootein).deliver_later
        end
      end
    end
  end

end
