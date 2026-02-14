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
