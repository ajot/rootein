# Rootein '26 - Decisions

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

### 2026-02-14: Presentation logic in the controller, not the model
**Decision:** Put `random_greeting` as a private method in `DashboardController`, not on User or any model.
**Why:** It's presentation logic — how to greet the user on a specific page. Models hold domain logic (what a rootein *is*, how streaks work). Controllers coordinate and prepare data for views. Greeting doesn't describe anything about the domain. If it grows complex later, extract to a helper module.

### 2026-02-14: Dashboard as a separate controller
**Decision:** Created `DashboardController` instead of adding a dashboard action to `RooteinsController`.
**Why:** The dashboard aggregates multiple data sources (slacking rooteins, on-target rooteins, random tip, greeting). It's its own concept, not a view of the rooteins resource. One controller per concept — Rails convention.

### 2026-02-14: No premature partial extraction
**Decision:** Kept the calendar markup inline in `rooteins/show.html.erb` instead of extracting it into a `_calendar.html.erb` partial.
**Why:** DHH philosophy — premature abstraction is worse than duplication. There's only one place the calendar is used. Extracting it would add indirection with zero reuse benefit. If a second calendar view appears later, then extract.

### 2026-02-14: Sectioned update for account settings
**Decision:** Used a single `AccountController` with a hidden `section` parameter to handle profile, password, and notification updates.
**Why:** One controller per concept. Account settings is one concept, even though it has multiple forms. The `section` parameter routes to different strong parameter methods. Avoids three separate controllers for one page.

### 2026-02-14: Singular resource route for account
**Decision:** Used `resource :account` (singular) with `controller: "account"` instead of `resources :accounts`.
**Why:** There's only one account per user — no `:id` in the URL makes sense. The `controller:` option prevents Rails from looking for `AccountsController` (pluralized).

### 2026-02-14: Defer Resend gem to deployment phase
**Decision:** Use Rails' built-in mail delivery (test mode) in development. Add Resend gem only when deploying to production.
**Why:** DHH philosophy — don't add gems until you feel the pain. In development, emails show up in the server log. The Resend gem is only needed for actual delivery in production. Every gem is a dependency to maintain.

### 2026-02-14: Solid Queue recurring schedule for reminders
**Decision:** Used `config/recurring.yml` with Solid Queue instead of a separate cron scheduler or Sidekiq.
**Why:** Solid Queue ships with Rails 8. No Redis dependency. The recurring schedule configuration is declarative YAML — easy to read, version-controlled, and doesn't require a separate process.

### 2026-02-14: Separate landing page controller and navbar
**Decision:** Created `LandingController` with its own navbar inside the view, rather than conditionalizing the app layout's navbar.
**Why:** Unauthenticated visitors need completely different navigation ("Log In | Register") than logged-in users (tabs for Dashboard, My Rooteins, etc.). Keeping them separate avoids messy conditionals in the layout.

### 2026-02-14: View helper for streak badges
**Decision:** Created `streak_badge(rootein)` in `RooteinsHelper` using `content_tag` instead of a partial.
**Why:** A partial would be overkill for a single HTML element. View helpers are the right place for small, reusable display components. The badge is used on 3 different pages (dashboard, index, show sidebar). `content_tag` builds safe HTML without ERB template overhead.

### 2026-02-14: Match the original 2009 visual design
**Decision:** Rebuilt all views to closely match the original Rootein screenshots — dark navbars, blue gradients, orange headers, streak badges, tab navigation.
**Why:** The original design was proven and recognizable. Rebuilding with the same visual identity shows how Rails 8 + Tailwind can reproduce any design. The original CSS was hand-written; now it's utility classes. Same result, better maintainability.

### 2026-02-14: Drag-and-drop reorder with Stimulus, no gem
**Decision:** Built drag-and-drop reorder for rooteins using a custom Stimulus controller (`sortable_controller.js`) and the HTML5 Drag and Drop API. Added a `position` integer column to persist order.
**Why:** A gem like `acts_as_list` or a JS library like SortableJS would add dependencies for a simple feature. The HTML5 Drag and Drop API is built into every browser. The Stimulus controller is 50 lines. `update_columns` bypasses validations for fast bulk position updates. Keep it simple.

### 2026-02-14: Landing page image carousel with Stimulus
**Decision:** Built an auto-cycling image carousel with a custom Stimulus controller (`carousel_controller.js`) instead of using a carousel library.
**Why:** The carousel is dead simple — show/hide images on a 2-second interval. 20 lines of Stimulus. No need for Swiper, Glide, or any library. `connect()` starts the timer, `disconnect()` cleans it up. Stimulus lifecycle methods make this trivial.

### 2026-02-14: Constrain landing page content width with `max-w-5xl`
**Decision:** Added `max-w-5xl` (1024px) to all inner container divs on the landing page. Outer sections keep full-width backgrounds.
**Why:** Content stretched too wide on large screens. `max-w-5xl` matches the compact feel of the original design. `max-w-4xl` (896px) would cramp the 4-column feature row; `max-w-6xl` (1152px) would still feel too spread out. The pattern — full-bleed outer div + constrained inner container — is standard responsive design.
