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
