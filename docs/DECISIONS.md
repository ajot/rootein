# rootein-again - Decisions

> Log the decisions you make as you build.
> Created 2026-02-13 with [mint-cli](https://github.com/ajotwani/mint-cli)

---

### 2026-02-13: Rails 8 with Hotwire + Tailwind
**Decision:** Use Rails 8 with Hotwire (Turbo Frames, Turbo Streams, Stimulus) and Tailwind CSS.
**Why:** Rails 8 ships with all of these by default. No SPA needed — server-rendered HTML with sprinkles of interactivity is perfect for a habit tracker.

### 2026-02-13: Built-in authentication (has_secure_password)
**Decision:** Use Rails 8's built-in `has_secure_password` and the auth generator instead of Devise or other gems.
**Why:** Rails 8 ships with an auth generator. No external dependency needed for a simple app with email/password login.

### 2026-02-13: Solid Queue for background jobs
**Decision:** Use Solid Queue (Rails 8 default) for background job processing.
**Why:** No Redis dependency. Stores jobs in the database. Perfect for email reminders.

### 2026-02-13: PostgreSQL
**Decision:** Use PostgreSQL as the database.
**Why:** Required for DigitalOcean App Platform deployment. Also gives us proper date handling and indexing for the completions table.

### 2026-02-13: DigitalOcean App Platform for deployment
**Decision:** Deploy to DigitalOcean App Platform with a managed PostgreSQL database.
**Why:** Simple container-based deployment, managed database, no server administration.

### 2026-02-13: Custom calendar (no gem)
**Decision:** Build the calendar view with custom ERB + Stimulus instead of using a calendar gem.
**Why:** The calendar is simple enough (show days in a month, click to toggle). A gem would be overkill and harder to customize.

### 2026-02-13: Start with the smallest thing that works
**Decision:** Build in phases, starting with a single Rootein on a page, no auth, no styling.
**Why:** DHH philosophy — don't over-plan. Feel the pain before adding complexity.
