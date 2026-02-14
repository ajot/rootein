# Rootein — Build Plan

> Rebuild of the original Rootein habit tracker (2009) with Rails 8, Hotwire, and Tailwind CSS.
> Philosophy: start with the smallest thing that works, add complexity only when you feel the pain.

## Data Models

```
User
  - email:string
  - name:string
  - password_digest:string (via has_secure_password)
  - notification_email:boolean (default: true)
  - time_zone:string

Rootein (a habit)
  - user_id:references
  - name:string
  - active:boolean (default: true)
  - reminder_time:time (nullable)
  - remind_on_slack:boolean (default: false)
  - created_at (acts as "started on" date)

Completion (a checked-off day)
  - rootein_id:references
  - completed_on:date
  - unique index on [rootein_id, completed_on]

Tip (motivational tips)
  - body:text
```

## Build Phases

### Phase 1: One Rootein in the Database ← IN PROGRESS
- [x] `rails new . --css=tailwind --database=postgresql --name=rootein` (generated app in existing dir)
- [x] Renamed app module to `RooteinApp` to free up `Rootein` for the model
- [x] `bin/rails db:create` (created rootein_development and rootein_test databases)
- [x] `bin/rails generate model Rootein name:string` + `db:migrate`
- [x] Tested in `rails console` — created 2 rooteins, verified CRUD works
- [ ] Generate a controller and show rooteins on a page — ugly, no auth, no styling

### Phase 2: The Calendar
- [ ] Generate `Completion` model (rootein_id, completed_on, unique index)
- [ ] Build a simple calendar view for a single rootein (ERB)
- [ ] Click a day to toggle completion (Turbo Stream for instant feedback)
- [ ] Show streak count — the core mechanic of the app

### Phase 3: Authentication
- [ ] Use Rails 8 built-in `has_secure_password` + auth generator
- [ ] Registration, login, logout
- [ ] Scope rooteins to current user
- [ ] Nav bar with greeting and navigation links

### Phase 4: CRUD for Rooteins
- [ ] New/Edit/Delete rootein forms
- [ ] Name field with character counter (Stimulus)
- [ ] Reminder time picker, "Remind me when slacking" checkbox
- [ ] Manage page — table of all rooteins with active toggle, edit/delete

### Phase 5: Dashboard (Home)
- [ ] Personalized greeting (random language)
- [ ] Three-column layout:
  - "You are slacking on" (red) — 0-day streak rooteins
  - "You are on target on" (green) — active streak rooteins
  - "Rootein Tip" (blue) — random tip from tips table
- [ ] Color-coded streak badges

### Phase 6: My Rooteins Page
- [ ] Left sidebar: list of active rooteins with streak badges
- [ ] Right side: calendar view for selected rootein
- [ ] Click days to toggle completions (Turbo Frames)
- [ ] Prev/Next month navigation
- [ ] Motivational messages based on streak status

### Phase 7: Account & Notifications
- [ ] Account settings page with tabs (Account / Password / Notifications)
- [ ] Email notification preferences
- [ ] Time zone selection

### Phase 8: Email Reminders
- [ ] Action Mailer for reminder emails
- [ ] Solid Queue for background job processing
- [ ] Daily job: find rooteins with reminders due, send emails
- [ ] "Slacking" notification when streak broken for 3+ days

### Phase 9: Landing Page
- [ ] Public landing page (unauthenticated)
- [ ] Tagline, feature highlights, signup CTA

### Phase 10: Deployment
- [ ] Dockerfile for DigitalOcean App Platform
- [ ] PostgreSQL managed database on DO
- [ ] Environment variables for secrets
- [ ] Production configuration

## Stimulus Controllers

| Controller | Purpose |
|-----------|---------|
| `calendar_controller.js` | Handle day clicks, toggle completions via Turbo |
| `character_counter_controller.js` | Live character count on rootein name field |
| `tabs_controller.js` | Tab switching on account page |

## Verification

After each phase:
1. Run `bin/dev` and test in browser
2. Use `rails console` to verify data
3. Run `rails test` for any tests written
