require "test_helper"

class ReminderMailerTest < ActionMailer::TestCase
  test "rootein_reminder" do
    mail = ReminderMailer.rootein_reminder
    assert_equal "Rootein reminder", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "slacking_alert" do
    mail = ReminderMailer.slacking_alert
    assert_equal "Slacking alert", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
