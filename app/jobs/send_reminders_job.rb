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
        if rootein.current_streak == 0 && days_since_last(rootein) >= 3
          ReminderMailer.slacking_alert(user, rootein).deliver_later
        end
      end
    end
  end

  private

  def days_since_last(rootein)
    last = rootein.completions.order(completed_on: :desc).first
    last ? (Date.today - last.completed_on).to_i : 999
  end
end
