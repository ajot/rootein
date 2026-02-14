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
