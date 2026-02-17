# Rootein

**A habit tracker that refuses to die.**

Pick the habits you want to build. Check off days. Watch your streaks grow. That's it.

[rootein.app](https://rootein.app)

---

## The Backstory

Rootein was first built in **2009** by [Amit](https://x.com/amit) and [Kunal](https://x.com/duak) — Ruby on Rails, hand-written CSS, no frameworks, no shortcuts. We were learning as we went, writing every line by hand over a few months. It worked. Green meant you were on target. Red meant you were slacking. Simple, and effective.

Then, like most side projects, life happened. The app went offline. The code gathered dust.

**Seventeen years later, I dusted it off.** Same idea. Same feel. But this time, [Claude Opus 4.6](https://claude.ai) drove most of the implementation — the UI, calendar logic, drag-and-drop reordering, email reminders, and the about page. I handled the scaffolding and made the tech stack decisions.

What took months in 2009 took hours in 2026.

> Here's a [video of the original Rootein](https://www.youtube.com/watch?v=o9JG7v2G0KA) from back in the day.

<details>
<summary>The original 2009 landing page</summary>

![Original Rootein (2009)](docs/CleanShot%202026-02-14%20at%2021.55.49@2x.png)
</details>

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Rails 8.0 |
| Language | Ruby 3.2 |
| Database | PostgreSQL |
| Frontend | Hotwire (Turbo + Stimulus) |
| Styling | Tailwind CSS |
| Asset Pipeline | Propshaft + Import Maps |
| Web Server | Puma + Thruster |
| Auth | `has_secure_password` (bcrypt) — no Devise |
| Deployment | DigitalOcean App Platform |

No frontend frameworks. No unnecessary gems. Just Rails, the [DHH](https://x.com/dhh) way.

---

## Getting Started

### Prerequisites

- Ruby 3.2.2
- PostgreSQL

### Setup

```bash
# Clone the repo
git clone https://github.com/ajotwani/rootein-again.git
cd rootein-again

# Install dependencies, create DB, run migrations
bin/setup

# Start the dev server (Rails + Tailwind watcher)
bin/dev
```

The app will be available at `http://localhost:3000`.

---

## Environment Variables

For local development, the defaults should just work. For production, you'll need:

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | PostgreSQL connection string |
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` |

---

## Documentation

Claude and I kept notes along the way. Every decision, every lesson, every phase of the plan — it's all in the repo.

| File | What's in it |
|------|-------------|
| [WHY.md](docs/WHY.md) | The vision — why this exists and what it's intentionally not solving |
| [PLAN.md](docs/PLAN.md) | The build plan — 10 phases from "one rootein in the database" to deployment |
| [DECISIONS.md](docs/DECISIONS.md) | Every stack decision, logged as we made them. Rails 8, no Devise, no SPA |
| [LEARNINGS.md](docs/LEARNINGS.md) | What I learned — Rails concepts, DHH philosophy, gotchas, and patterns |

---

## Credits

Built by [Amit](https://x.com/amit). Originally co-created with [Kunal](https://x.com/duak) in 2009.

Rebuilt in 2026 with [Claude Opus 4.6](https://claude.ai) doing the heavy lifting.

Inspired by the [DHH](https://x.com/dhh) way of building for the web.
