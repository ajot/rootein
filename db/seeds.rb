# Motivational tips
tips = [
  "It takes 21 days to form a habit. Keep going!",
  "Don't break the chain — consistency beats intensity.",
  "Small daily improvements lead to stunning results.",
  "You don't have to be extreme, just consistent.",
  "The secret of getting ahead is getting started.",
  "A habit is a cable; we weave a thread of it each day.",
  "Motivation gets you started. Habit keeps you going.",
  "Success is the sum of small efforts repeated day in and day out.",
  "We are what we repeatedly do. Excellence is not an act, but a habit.",
  "The best time to start was yesterday. The next best time is now."
]

tips.each do |body|
  Tip.find_or_create_by!(body: body)
end

puts "Seeded #{Tip.count} tips."
