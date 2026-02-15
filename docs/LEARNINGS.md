# Rootein — Learnings

> Things I learned while building Rootein. Insights, gotchas, and Rails concepts explained.

---

## Phase 1: One Rootein in the Database

### `rails new .` vs `rails new appname`
Use `.` (dot) to generate a Rails app inside an existing directory instead of creating a new subdirectory. Useful when you already have a git repo or docs set up. The `--name=rootein` flag sets the internal module name.

### App module vs model name collision
Rails reserves the app module name (e.g., `Rootein::Application`). If your core model shares that name, rename the app module (we used `RooteinApp`) — the model is the domain concept that matters, the app module is just plumbing.

### `brew services start` vs `run`
- `start` — runs now AND auto-starts on every reboot (persistent)
- `run` — runs now but won't auto-start on reboot (one-time)

### REPL (Read-Eval-Print Loop)
An interactive programming environment that reads your input, evaluates it, prints the result, and loops. `bin/rails console` is a REPL with your entire Rails app loaded — models, database, everything. When you type `Rootein.all`, it generates real SQL and hits your Postgres database.

### Rails console as a design tool (DHH approach)
Before building UI, interact with your models in the console. Verify the data layer works, get a feel for the API, discover issues early.

### Instance variables (`@`) pass data to views
In a controller, `@rooteins = Rootein.all` makes the data available in the view. A local variable (without `@`) stays trapped in the controller.

### ERB tags: `<%=` vs `<%`
- `<%= expression %>` — outputs the result to the page (the `=` means "print this")
- `<% code %>` — executes code silently (for loops, conditionals)
- Using `<%= @items.each ... %>` will print the raw array at the end — use `<% @items.each ... %>` instead

### `root` route in Rails
`root "controller#action"` defines what loads at `http://localhost:3000/`. The generator creates `get "rooteins/index"` which only works at `/rooteins/index` — setting `root` gives you a proper homepage.

### Tailwind's Preflight reset
Tailwind strips ALL default browser styles (no bold headings, no list bullets, no margins). Everything starts from zero — you style intentionally with utility classes. For ordered lists, add `class="list-decimal list-inside"` to `<ol>`.

### Rails adds columns for free
You only define your custom columns. Rails automatically adds `id`, `created_at`, and `updated_at` to every table.

### `RooteinApp` in SQL comments
Rails 8 tags every SQL query with your app name in comments (`/*application='RooteinApp'*/`). Useful for debugging in production when multiple apps share a database.

---

## Phase 2: The Calendar

### `references` type in model generator
`rootein:references` does three things automatically:
1. Adds a `rootein_id` integer column
2. Creates a database index on `rootein_id` (for fast lookups)
3. Adds `belongs_to :rootein` in the model file

### Compound unique index
`add_index :completions, [:rootein_id, :completed_on], unique: true` — neither column is unique alone (a rootein has many dates, a date has many rooteins), but the combination must be unique. Database-level guarantee: one check per habit per day.

### Edit migrations before running them
Migrations are like version control for your schema. Once run, they're "applied." It's cleaner to inspect and tweak a migration before running it than to roll back later.

### Three Rails environments
- **development** — your local machine (`rootein_development` database)
- **test** — used by `rails test` (`rootein_test` database)
- **production** — the live app (DigitalOcean, configured later via environment variables)

### `has_many` and `belongs_to` — the one-to-many pair
`belongs_to :rootein` (in Completion) and `has_many :completions` (in Rootein) are two halves of one relationship. Once both are in place, you can traverse in either direction: `rootein.completions` returns all completions, `completion.rootein` returns the parent. Always define both sides.

### `dependent: :destroy`
Added to `has_many :completions, dependent: :destroy`. When a rootein is deleted, Rails automatically deletes all its completions too. Without this, you'd have orphaned rows in the completions table pointing to a rootein_id that no longer exists.

### Belt and suspenders: database index + model validation
The compound unique index in the migration prevents duplicate completions at the **database** level (hard crash). The `validates :completed_on, uniqueness: { scope: :rootein_id }` prevents them at the **application** level (friendly error message). Use both — the validation gives nice errors, the index is the safety net if code bypasses validations.

### `uniqueness: { scope: :rootein_id }`
Without `scope`, Rails would enforce uniqueness of `completed_on` across ALL completions globally. With `scope: :rootein_id`, it means "unique within a single rootein" — two different habits can be completed on the same day, but the same habit can't be marked twice.

### `create` vs `create!` (bang methods)
- `create` — fails silently, returns an unsaved object with `id: nil`. Call `.errors.full_messages` to see what went wrong.
- `create!` — raises `ActiveRecord::RecordInvalid` exception immediately on failure.
- **How to tell if a record saved:** check for `id: nil` (not saved) vs a real number (saved), or call `.persisted?`.
- **Rule of thumb:** use `create!` in the console (loud failures), use `create` in controllers (so you can re-render forms with error messages).

### Association methods fill in foreign keys automatically
`rootein.completions.create!(completed_on: Date.today)` — you don't need to pass `rootein_id`. Because you're calling through the association, Rails fills in the foreign key for you. That's the power of `has_many`.

### `resources` and nested routes
`resources :rooteins, only: [:index, :show]` generates RESTful routes. Adding `do ... end` with nested `resources :completions` creates URLs like `/rooteins/1/completions`. The parent ID is baked into the URL and available as `params[:rootein_id]` in the nested controller. Use `only:` to limit to just the actions you need.

### `button_to` vs `link_to`
`link_to` generates a GET request (for navigation). `button_to` generates a mini `<form>` with the correct HTTP method (POST/DELETE) and an automatic CSRF token. Use `button_to` whenever you're creating or destroying data — Rails rejects POST/DELETE without a valid CSRF token as XSS protection.

### ERB `do` must stay on the same line
When using `button_to ... do` or any block in ERB, the `do` keyword must be on the same line as the method call's last argument (inside the same `<%= %>` tag). If `do` wraps to a new line, ERB's parser sees it as a separate statement and throws `syntax error, unexpected 'do'`. This doesn't happen in plain `.rb` files — ERB's line-by-line compilation is stricter.

### `.pluck` vs loading full objects
`@rootein.completions.pluck(:completed_on)` returns just an array of dates — one column, no model objects. Much lighter than loading full `Completion` records when you only need to check which days are completed.

### `.to_set` for O(1) lookups
Converting an array to a `Set` makes `.include?` checks instant (O(1) hash lookup) instead of scanning the array (O(n)). Useful when you're checking membership in a loop — like checking 31 calendar days against completed dates.

### Domain logic belongs in the model (DHH philosophy)
The `current_streak` method lives in `Rootein`, not in the controller or view. The streak is a property of a rootein — it's domain logic. DHH's philosophy: models are where your business logic lives. Controllers should only coordinate (fetch data, redirect). Views should only display. By putting it on the model, you can call `rootein.current_streak` from anywhere — console, controller, view, tests, mailers. If you find yourself writing logic in a controller that describes *what something is* rather than *what to do next*, it belongs in the model.

### Start simple, upgrade when you feel the pain (DHH philosophy)
We used `redirect_to` after toggling a completion instead of Turbo Streams. A full-page redirect works fine. If it feels slow later, we upgrade to Turbo Streams for instant no-reload feedback. Don't optimize before there's a problem. This applies everywhere — don't add caching until it's slow, don't add background jobs until the request is too long, don't add a gem until the built-in way hurts.

### Belt and suspenders for data integrity (DHH philosophy)
We validate uniqueness of completions at two levels: a compound unique index in the database AND `validates :completed_on, uniqueness: { scope: :rootein_id }` in the model. The database index is the hard safety net — it prevents duplicates even if code bypasses Rails (raw SQL, race conditions, concurrent requests). The model validation gives user-friendly error messages. One without the other is incomplete. This "defense in depth" pattern applies to any critical data constraint.

### `1.day` — ActiveSupport time extensions
`Date.today - 1.day` gives you yesterday. Rails extends Ruby's numbers so you can write `3.hours`, `2.weeks`, `1.month.ago`, `30.minutes.from_now`. Makes time math readable.

### `before_action` for shared setup
`before_action :set_rootein` runs a method before every action in the controller. Extracts shared logic (like finding the parent record) into one place instead of repeating it in every action.

---

## Phase 3: Authentication

### Rails 8 auth generator
`bin/rails generate authentication` creates the full auth stack: `User` model with `has_secure_password`, `Session` model (database-backed sessions), `Current` model (thread-safe global), `Authentication` concern, login/logout controllers, password reset mailer, and routes. No gems needed.

### `has_secure_password`
One line in the User model that gives you: bcrypt password hashing, `password` and `password_confirmation` virtual attributes, and an `authenticate` method. You set `password`, Rails stores `password_digest`. The plaintext is never saved.

### `[FILTERED]` in console output
Rails 8 automatically hides sensitive fields (`email_address`, `password_digest`) in console and log output. The data is in the database — it's just hidden from display to prevent credential leaks in logs or screenshots.

### bcrypt hash anatomy
`$2a$12$0pFy...` — `$2a$` = bcrypt algorithm, `$12$` = 12 rounds of hashing (cost factor). Each hash includes a unique salt, so two users with the same password get different digests. Even with database access, passwords can't be reversed.

### `Current` — thread-safe global state
`Current.user` gives you the logged-in user from anywhere (models, controllers, views, mailers). It's backed by `ActiveSupport::CurrentAttributes`, which is automatically reset between requests. The `Authentication` concern sets `Current.session` on each request, and `Current.user` delegates to it.

### Authentication concern — secure by default (DHH philosophy)
The concern adds `before_action :require_authentication` to `ApplicationController`, meaning every page requires login by default. Controllers opt *out* with `allow_unauthenticated_access` rather than opting in. Secure by default — you can't accidentally forget to protect a page.

### Authorization through scoping (DHH philosophy)
`Current.user.rooteins.find(params[:id])` instead of `Rootein.find(params[:id])`. The query is automatically scoped to `WHERE user_id = ?`. If the rootein doesn't belong to the logged-in user, Rails raises `RecordNotFound` (404). No explicit `if rootein.user == current_user` check needed. Simple, foolproof, and impossible to forget.

### Migration with existing data — nullable first, backfill, then constrain
When adding a foreign key to a table that already has rows, don't use `null: false` in the migration — it will fail because existing rows have `NULL` for the new column. Instead: (1) add the column as nullable, (2) backfill the data, (3) optionally add the NOT NULL constraint in a follow-up migration.

### `bin/rails runner`
Executes a one-liner with your full Rails environment loaded, without dropping into an interactive console. `bin/rails runner "Rootein.update_all(user_id: 1)"` — perfect for quick data fixes and deploy scripts.

### Layout file and `yield`
`application.html.erb` wraps every page. Shared UI like nav bars goes here. `<%= yield %>` is where each page's specific content gets injected. Wrap nav in `if authenticated?` so the login page doesn't show a broken nav.

### `ActiveModel::UnknownAttributeError`
Rails rejects attributes that don't match any column: `User.create!(email_adddres: ...)` raises an error immediately. Catches typos early instead of silently ignoring them.

---

## Phase 4: CRUD for Rooteins

### `turbo_confirm` — confirmation dialogs without JavaScript
`data: { turbo_confirm: "Are you sure?" }` on a `button_to` or `link_to` makes Turbo intercept the click and show a browser `confirm()` dialog. If the user clicks "OK," it submits. "Cancel" does nothing. This is Hotwire's philosophy: behavior through HTML attributes, not custom JS. The old Rails UJS equivalent was `data: { confirm: "..." }` — Rails 8 replaced UJS with Turbo.

### Flash messages — the one-time message bus
Three connected pieces: (1) Controller sets the flash: `redirect_to @rootein, notice: "Rootein created!"` stores the message in the session cookie. (2) Layout reads it: `<% if notice %>` displays the message. (3) Flash auto-clears after one request — it survives the redirect, shows once, then self-destructs. This is why it lives in `application.html.erb` — it needs to work on every page. `notice` (green/success) and `alert` (red/error) are the two Rails conventions.

### `form_with(model: rootein)` — one form, two behaviors
Rails inspects the model to decide everything: `rootein.new_record?` → POST to `/rooteins` (create). `rootein.persisted?` → PATCH to `/rooteins/1` (update). The submit button text auto-changes too: "Create Rootein" vs "Update Rootein." Convention over configuration at its finest.

### Partials (underscore-prefixed files)
`_form.html.erb` is a **partial** — a reusable view fragment. Both `new.html.erb` and `edit.html.erb` call `<%= render "form", rootein: @rootein %>` to share the same form. The local variable `rootein:` is passed in explicitly so the partial doesn't depend on instance variables. DRY without abstraction overhead.

### Strong Parameters — `params.expect`
`params.expect(rootein: [:name, :active, :reminder_time, :remind_on_slack])` whitelists which attributes can be mass-assigned. Without this, a malicious user could POST `user_id: 999` and reassign a rootein to someone else. Rails 8's `expect` is stricter than the older `require/permit` pattern — it raises if the parameter structure doesn't match.

### `render :new, status: :unprocessable_entity` — re-render on failure
When validation fails, we re-render the form (not redirect). This preserves the user's input and shows error messages inline. The `422 Unprocessable Entity` status tells Turbo not to cache or push this response into the history — the user stays on the form with their errors visible.

### Boolean columns get `?` methods for free
Rails automatically creates a `?` method for every boolean column. `rootein.active?` returns `true`/`false`. You never need to write `rootein.active == true`. This works for any boolean: `remind_on_slack?`, `admin?`, etc.

### Database defaults backfill existing rows
`add_column :rooteins, :active, :boolean, default: true, null: false` — Postgres applies the default to all existing rows during the migration. No manual backfill needed (unlike adding a foreign key). Use defaults for booleans and simple values; use the nullable-then-backfill pattern for foreign keys.

---

## Phase 5: Dashboard

### `.sample` — pick a random element from an array
`greetings.sample` returns a random element each time it's called. Each page load shows a different greeting: "Hola, you!", "Konnichiwa, you!", "Bonjour, you!" etc. Simple, built-in Ruby — no gem needed for basic randomness.

### Presentation logic belongs in the controller, not the model
The `random_greeting` method lives as a private method in `DashboardController`, not on any model. It's presentation logic (how to greet the user), not domain logic (what a rootein *is*). If it grew more complex (greeting based on time of day, user's locale), you'd extract it to a helper module. For now, a private method is the right size. Rule of thumb: models = domain logic, controllers = coordination + presentation setup, views = display.

### Scopes — named query shortcuts
`scope :active, -> { where(active: true) }` lets you write `Current.user.rooteins.active` instead of `Current.user.rooteins.where(active: true)`. Reads like English and chains with other queries. The `->` is a lambda — a stored block of code that only runs when called.

### `find_or_create_by!` — idempotent seeding
Used in `db/seeds.rb` to prevent duplicates when seeding. It finds an existing record by the given attributes, or creates one if it doesn't exist. Run `db:seed` ten times and you still get the same data. The `!` raises on validation failure.

### `Tip.order("RANDOM()").first` — random row from Postgres
Postgres picks a random row each time. Fine for small tables (our 10 tips). For millions of rows you'd use `Tip.offset(rand(Tip.count)).first` to avoid sorting the whole table.

### Separate controllers for separate concepts
The dashboard is its own controller, not shoehorned into `RooteinsController`. It aggregates data from multiple sources (rooteins split by status + a random tip). One controller per resource/concept is the Rails convention.

---

## Phase 6: My Rooteins Page

### Don't extract partials prematurely
The calendar could have been a `_calendar.html.erb` partial — but there's only one place it's used. Extracting it would add indirection (partial file, local variable passing) with zero reuse benefit. Wait until you actually need the same markup in two places before extracting. DHH philosophy: premature abstraction is worse than duplication.

### Monday-start calendar grid
`(@date.beginning_of_month.wday - 1) % 7` calculates the offset for a Monday-start calendar. Ruby's `wday` returns 0=Sunday, 1=Monday, ..., 6=Saturday. Subtracting 1 and modding by 7 shifts Sunday from 0 to 6, making Monday the first column. The `%` modulo handles the wrap-around.

### Motivational messages with streak thresholds
Instead of a single static message, the calendar show page uses `if/elsif/else` to display different messages based on `current_streak`: 0 days (get started!), 1-6 (building), 7-20 (real habit), 21+ (it's a Rootein now). Keeps users engaged at every stage. Simple conditional logic — no gem or framework needed.

---

## Phase 7: Account & Notifications

### Sectioned update pattern — one controller, multiple forms
`AccountController#update` uses a hidden `params[:section]` field to route to different strong parameter methods (`profile_params`, `password_params`, `notification_params`). Each form on the page submits to the same `PATCH /account` endpoint with a different section value. This avoids three separate controllers for what is conceptually one page.

### `resource` (singular) vs `resources` (plural)
`resource :account` (singular) generates routes without an `:id` parameter — there's only one account per logged-in user. But Rails pluralizes the controller name: it looks for `AccountsController`. Override with `controller: "account"` to use `AccountController` (singular, matching the concept).

### `.presence` — nil-or-empty in one call
`Current.user.name.presence || "fallback"` returns the name if it's a non-blank string, or `nil` if it's empty/nil — letting the `||` kick in. Without `.presence`, an empty string `""` is truthy and the fallback never fires. Useful for user-facing names where a blank name should fall back to email prefix.

### `time_zone_select` — built-in Rails helper
Rails ships with `time_zone_select(:user, :time_zone)` that renders a dropdown of all `ActiveSupport::TimeZone` names. No gem needed. The values match what `Time.zone=` expects, so time zone support works end-to-end.

---

## Phase 8: Email Reminders

### Action Mailer — HTML + text templates
Each mailer method (e.g., `rootein_reminder`) gets two templates: `.html.erb` and `.text.erb`. Rails sends a multipart email with both versions — the recipient's email client picks whichever it supports. Always provide both: some corporate clients and accessibility tools prefer plain text.

### Mailer previews for development
`test/mailers/previews/reminder_mailer_preview.rb` lets you view rendered emails at `/rails/mailers/reminder_mailer/rootein_reminder` without actually sending anything. Change the preview, reload the page — instant feedback loop. Far faster than sending test emails.

### Solid Queue recurring schedule
`config/recurring.yml` defines jobs that run on a schedule. `send_reminders: class: SendRemindersJob, schedule: "at 8am every day"` — Solid Queue handles the cron-like scheduling, no Redis or Sidekiq needed. Jobs are stored in the database and processed by Solid Queue workers.

### Don't add gems until you feel the pain (DHH philosophy)
We almost added Resend for email delivery but realized: in development, Rails uses test delivery (emails appear in the log). The gem is only needed in production. Defer it to the deployment phase. Every gem is a dependency to maintain — add them at the last responsible moment.

---

## Phase 9: Landing Page

### `allow_unauthenticated_access` — opting out of auth
The `Authentication` concern locks every page by default. `LandingController` and `RegistrationsController` use `allow_unauthenticated_access` to let visitors in without a session. This is the inverse of adding `before_action :authenticate_user!` per-controller — secure by default, explicit opt-out.

### `start_new_session_for` — auto-login after registration
After `User.create`, calling `start_new_session_for @user` creates a session and sets the cookie — the user lands on the dashboard already logged in. No redirect to the login page after signup. Small UX detail, big difference in perceived friction.

### Separate navbar for unauthenticated pages
The landing page needs "Log In | Register" links, not the app's nav tabs. Instead of adding conditionals to the layout navbar, the landing page renders its own navbar inside its view template. The `-mx-5 -mt-8` negative margins counteract the layout's padding so it can span full-width.

---

## Visual Overhaul: Matching the Original 2009 Design

### View helpers with `content_tag` for reusable UI components
`streak_badge(rootein)` in `RooteinsHelper` uses `content_tag` to build a badge (colored square with streak number + "days" label). This is used on the dashboard, index page, and show page sidebar. View helpers are the right place for reusable display logic — not models (no HTML in models), not partials (too heavy for a single HTML element).

### `controller_name` and `action_name` for active state detection
The layout navbar highlights the current tab using `controller_name == "dashboard"` to add a CSS class. Rails provides `controller_name` and `action_name` as view helpers — you don't need to pass flags from the controller. Clean way to handle active navigation states without adding instance variables.

### Negative margins to break out of layout padding
The landing page uses `-mx-5 -mt-8` to counteract the layout's `px-5 pt-8` padding. This lets a child view go full-width edge-to-edge even though the layout has padding. Common Tailwind pattern — negative margins pull the element outward by the same amount as the parent's padding.

---

## Stimulus — "The Modest JavaScript Framework"

### What is Stimulus?
Stimulus is a lightweight JavaScript framework created by the Basecamp/Hey team (DHH's company). It's part of the **Hotwire** stack that ships with Rails 8. Hotwire has two pieces: **Turbo** (makes page navigation fast, handles forms, streams HTML updates) and **Stimulus** (adds small, focused JS behaviors to server-rendered HTML). The key philosophy: HTML is the source of truth, not JavaScript. You don't build your UI in JS and render it to the DOM (like React). Instead, Rails renders the HTML on the server, and Stimulus sprinkles interactivity on top.

### Three core concepts — controllers, targets, actions
Stimulus has just three ideas, all wired through `data-` attributes in HTML:

1. **Controllers** — a JS class that manages a piece of the page. `<div data-controller="carousel">` tells Stimulus: "find `carousel_controller.js` and connect it to this div."
2. **Targets** — named references to DOM elements (replaces `querySelector`). `<img data-carousel-target="slide">` — in the controller, `this.slideTargets` gives you an array of all matching elements. Declared with `static targets = ["slide"]` at the top of the class.
3. **Actions** — event handlers wired in HTML (replaces `addEventListener`). `<div data-action="dragstart->sortable#dragstart">` means: "when `dragstart` fires on this element, call the `dragstart()` method on the `sortable` controller."

### Why Stimulus instead of React/Vue?
Stimulus is intentionally tiny. It doesn't manage state, doesn't have a virtual DOM, and doesn't render HTML. It's for **behavior**, not **rendering**. With React/Vue, JavaScript builds everything (rendering + behavior + state). With Stimulus, the **server** (Rails ERB) builds the HTML — JS only adds behavior (clicks, timers, drag). This is why the carousel controller is 20 lines and the sortable controller is 50 lines. Stimulus doesn't try to do more than it needs to.

### How we use it in Rootein
- `carousel_controller.js` — `connect()` starts a 2-second timer, `disconnect()` cleans it up, `next()` cycles through `slide` targets by toggling `hidden`.
- `sortable_controller.js` — handles drag-and-drop via HTML5 events (`dragstart`, `dragover`, `drop`), calculates drop position using `getBoundingClientRect()`, persists new order via `fetch()`.

---

## Drag-and-Drop Reorder

### Stimulus `connect()` and `disconnect()` lifecycle
Stimulus controllers have lifecycle callbacks: `connect()` fires when the controller's element enters the DOM, `disconnect()` fires when it leaves. In the carousel controller, `connect()` starts a `setInterval` timer; `disconnect()` calls `clearInterval` to prevent memory leaks. Always clean up timers, event listeners, and subscriptions in `disconnect()`.

### HTML5 Drag and Drop API — no library needed
The browser's built-in drag-and-drop uses four events: `dragstart` (user grabs an item), `dragover` (item hovers over a drop target — must call `preventDefault()` to allow dropping), `drop` (item is released), and `dragend` (cleanup). The `sortable_controller.js` uses `getBoundingClientRect()` to detect if the dragged item should go above or below the target based on the cursor's Y position relative to the element's midpoint.

### `update_columns` — bypass validations for bulk updates
`rootein.update_columns(position: index)` writes directly to the database without running validations, callbacks, or updating `updated_at`. This is intentional for the reorder endpoint — we're only changing sort position, and running full model validations on every item in the list would be wasteful. Use `update_columns` when you're certain the data is valid and you need speed.

### Collection routes — actions on the group, not one record
`collection { patch :reorder }` inside `resources :rooteins` creates `PATCH /rooteins/reorder` — an action on the collection (all rooteins), not a member (one rootein). Compare with `member { get :archive }` which creates `GET /rooteins/:id/archive`. Use collection routes when the action doesn't operate on a single record.

### CSRF tokens in `fetch()` requests
Rails rejects non-GET requests without a valid CSRF token. In the sortable controller, `fetch()` must include the `X-CSRF-Token` header, pulled from the `<meta name="csrf-token">` tag that Rails injects into the layout. Without it, the server returns `422 Unprocessable Entity`. Turbo and `button_to` handle this automatically — manual `fetch()` requires explicit inclusion.

### Stimulus targets — `data-*-target` attribute convention
`data-carousel-target="slide"` registers an element as a target. In the controller, `this.slideTargets` returns an array of all matching elements. The naming convention is `data-[controller]-target="[name]"`. Declared with `static targets = ["slide"]` at the top of the controller class. Targets are the Stimulus way to reference DOM elements without `querySelector`.

---

## Landing Page Polish

### Auto-cycling carousel with `setInterval`
The carousel controller cycles through images every 2 seconds using `setInterval`. Each tick hides the current slide (`classList.add("hidden")`) and shows the next. Modulo arithmetic (`(this.index + 1) % this.slideTargets.length`) wraps around to the first slide after the last. All slides except the first start with `class="hidden"` in the HTML.

### Full-bleed backgrounds with constrained content
A common responsive pattern: outer `<div>` elements carry full-width backgrounds (gradients, colors, borders) while inner `container mx-auto max-w-5xl` divs cap the content at 1024px. Tailwind's `container` sets `width: 100%` with responsive max-widths at each breakpoint. Adding `max-w-5xl` overrides the larger breakpoints (like `xl: 1280px`) with a hard 1024px ceiling.
