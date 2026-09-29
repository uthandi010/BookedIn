# BookedIn

An appointment-booking SaaS for small businesses — think a small Calendly. A business owner sets
up their services and weekly hours, invites staff, and gets a public booking page their customers
can use with no account at all.

Built to demonstrate a real scheduling problem, not just CRUD: computing actual free time slots
from a business's hours and existing bookings, and preventing two customers from ever double-booking
the same slot.

## Features

- **Auth** — register/login with JWT, PBKDF2-via-bcrypt password hashing (Rails' `has_secure_password`)
- **Businesses** — each business has its own services, weekly hours, staff, and appointments
- **Roles** — `Staff < Owner`, enforced server-side on every business-scoped request (a staff
  member can view appointments but can't manage services, hours, or invite people)
- **Availability engine** — given a business's opening hours, a service's duration, and its
  existing bookings, computes exactly which time slots are actually free that day
- **Double-booking prevention** — enforced at the model layer, not just the UI: booking an
  already-taken slot is rejected with a clear error, verified end-to-end in the test suite
- **Public booking page** (`/book/:slug`) — no login required: pick a service, pick a date, pick
  an open slot, book it

## Stack

| Layer | Tech |
| --- | --- |
| API | Ruby on Rails 8 (API-only), SQLite |
| Auth | JWT bearer tokens, `has_secure_password` (bcrypt) |
| Client | Vue 3 (`<script setup>`), Pinia, Vue Router, Vite |
| Tests | RSpec + FactoryBot (69 examples), Vitest + Vue Test Utils (15 examples) |

No paid services or cloud accounts are required to run this locally.

## Project layout

```
server/   # Rails API (models, controllers, the AvailabilityCalculator service object)
client/   # Vue 3 frontend (owner/staff dashboard + the public booking page)
```

## Running it locally

### API

```bash
cd server
bundle install
bin/rails db:migrate
bin/rails server -p 3001
```

Run the backend tests:

```bash
cd server
bundle exec rspec
```

### Client

```bash
cd client
cp .env.example .env.local   # adjust VITE_API_BASE_URL if needed
npm install
npm run dev
```

Run the frontend tests:

```bash
cd client
npm test
```

## How availability is computed

`AvailabilityCalculator` (`server/app/services/availability_calculator.rb`) is a plain Ruby
service object, not tied to a controller:

1. Look up the business's configured hours for that day of week. No hours for that day = closed,
   no slots.
2. Walk candidate start times across the open window, one every 30 minutes, each long enough to
   fit the requested service's duration.
3. Drop any candidate that overlaps an existing **confirmed** appointment (a cancelled one doesn't
   block anything), optionally scoped to one staff member, and drop anything already in the past.

Double-booking is still checked again at the model layer (`Appointment`'s
`no_overlap_with_existing_confirmed_appointment` validation) when the booking is actually created —
the availability list is a helpful preview, not the source of truth.

## Notes on the auth design

- Roles live on the **membership** (`BusinessMember`), not the user, so the same person could be
  Staff at one business and the Owner of another.
- Every business-scoped controller includes the `BusinessScoped` concern, which loads the business
  and checks membership before the action runs — a non-member gets `403` even with a valid ID.
- The JWT secret comes from Rails' own `secret_key_base`, which Rails auto-generates per
  environment in development/test. Nothing to configure locally; for a real deployment you'd set
  `RAILS_MASTER_KEY` from `config/credentials.yml.enc` as usual.

## What's intentionally left out

This is a portfolio-scale MVP, not a production SaaS. A few things that would come next: email
delivery for booking confirmations and staff invites (right now "invite" requires the person to
already have an account), per-staff working hours instead of one shared business calendar, and
recurring/multi-day services.
