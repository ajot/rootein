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

### 2026-02-14: Business logic lives in the model, not the controller
**Decision:** Put the `current_streak` calculation in the `Rootein` model, not in the controller or a helper.
**Why:** DHH philosophy — models are where your domain logic lives. The streak is a property of a rootein. By putting it on the model, you can call `rootein.current_streak` from anywhere — console, controller, view, tests, mailers. Controllers should only coordinate (fetch data, redirect). Views should only display. The model is the source of truth.

### 2026-02-14: Simple redirect over Turbo Streams (for now)
**Decision:** Use `redirect_to` after toggling a completion instead of Turbo Streams.
**Why:** DHH philosophy — start simple, add complexity when you feel the pain. A full-page redirect works. If the page feels slow later, upgrade to Turbo Streams. Don't optimize before there's a problem.

### 2026-02-14: Belt and suspenders for data integrity
**Decision:** Validate uniqueness of completions at both the database level (compound unique index) and the application level (`validates :completed_on, uniqueness: { scope: :rootein_id }`).
**Why:** The database index is the safety net — it prevents duplicates even if code bypasses Rails validations (raw SQL, race conditions, background jobs). The model validation gives friendly error messages. One without the other is incomplete.

### 2026-02-14: Rails 8 built-in auth over Devise
**Decision:** Use `bin/rails generate authentication` instead of the Devise gem.
**Why:** Rails 8 ships with everything we need: `has_secure_password`, session management, password resets. No external dependency, no black-box magic. We understand every line of the generated code because it's plain Rails — controllers, models, views we can read and modify. DHH philosophy: prefer the framework's built-in tools.

### 2026-02-14: Secure by default — require auth, then opt out
**Decision:** The `Authentication` concern requires login on every page. Individual controllers opt out with `allow_unauthenticated_access`.
**Why:** DHH philosophy — the secure default means you can't accidentally forget to protect a new page. Opting out is explicit and intentional. The alternative (opting in per-controller) is an invitation for security holes.

### 2026-02-14: Authorization through scoping, not conditionals
**Decision:** Use `Current.user.rooteins.find(params[:id])` instead of `Rootein.find(params[:id])` with a manual ownership check.
**Why:** Scoping queries through the current user makes unauthorized access structurally impossible — the SQL WHERE clause enforces it. No `if rootein.user == current_user` check to forget. The wrong ID simply returns 404. Simpler code, stronger security.
