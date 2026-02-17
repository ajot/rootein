# Rootein '26

> Document your vision and intent before writing code.
> Created 2026-02-13 with [mint-cli](https://github.com/ajotwani/mint-cli)

## I'm building this because:
- Rootein was a habit tracker I built in 2009 with Rails. The core idea still works: pick habits you want to build, check off days on a calendar, watch your streaks grow. Visual feedback (green = on target, red = slacking) keeps you honest.
- The original app is long dead, but the concept deserves a modern rebuild with Rails 8, Hotwire, and Tailwind CSS.
- It's also a chance to relearn Rails the DHH way — start with the smallest thing that works, add complexity only when you feel the pain.

## I'm intentionally not solving:
- Social features (sharing, leaderboards, friends)
- Mobile native app — responsive web is enough
- Complex analytics or reporting beyond streaks
- Gamification beyond streak counts and color feedback
- API for third-party integrations (for now)
- Slack reminders (deferred — checkbox exists but functionality is future)

## This will be done when:
- A user can sign up, create habits ("Rooteins"), and check off days on a calendar
- Streaks are calculated and displayed with color-coded feedback
- A dashboard shows which habits you're on target for and which you're slacking on
- Email reminders can be configured per habit
- The app is deployed and running on DigitalOcean App Platform
