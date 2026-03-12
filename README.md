# JackBuddies

Production-ready Rails app for a private IPL prediction group with signup approval, role-based admin controls, stage-based scoring, and an audit ledger.

## Stack
- Ruby 3.3+
- Rails 8.1+
- PostgreSQL
- Devise (authentication)
- Pundit (authorization)
- TailwindCSS + Hotwire (Turbo/Stimulus)
- Chartkick + Groupdate (charts)

## Features
- User signup enabled with admin approval workflow.
- Role model: `user` and `admin`.
- Pending users are blocked from league pages and redirected to an approval screen.
- Season-based IPL gameplay with lock-time pick editing.
- Stage-specific points rules per season (`league`, `qualifier`, `eliminator`, `final`).
- Audit-friendly points ledger (`points_events`) with voiding/rebuild on recalculation.
- Admin tools for user approval, CRUD for seasons/teams/matches, result entry, recalculation, pick edits, and manual point adjustments.
- Visibility rules: approved users can view leaderboard, picks, user stats, and history for any approved user.

## Setup
1. Install Ruby 3.3+ and PostgreSQL.
2. Install gems and JS deps:
```bash
bundle install
npm install
```
3. Prepare DB:
```bash
bin/rails db:create db:migrate db:seed
```
4. Run app:
```bash
bin/dev
```

## Docker Setup
1. Start the app and PostgreSQL:
```bash
docker compose up --build
```
2. Open the app at `http://localhost:3000`.

Notes:
- If your Docker install uses the legacy binary, run `docker-compose up --build` instead.
- The web container runs `bin/rails db:prepare` automatically on boot.
- Source code is bind-mounted, so Rails, Tailwind, and esbuild changes reload as you edit.
- PostgreSQL data is stored in the `postgres_data` Docker volume.
- To reset everything, run `docker compose down -v`.

## Import IPL 2025 Data
1. Place CSV files under `data/`:
   - `data/ipl_2025_matches.csv`
   - `data/ipl_2025_users.csv`
   - `data/ipl_2025_user_points.csv`
   - Optional: `data/ipl_2025_team_stats.csv`
2. Run import:
```bash
bin/rails data:import_ipl_2025
```
3. Import is idempotent and can be rerun safely (upserts by unique keys).

CSV format examples:
```csv
season_year,match_no,match_date,team_a,team_b,stage,winner_team,loser_team
2025,1,2025-03-22,KKR,RCB,LEAGUE,RCB,KKR
```
```csv
name,email
Bishan,bishan@example.com
```
```csv
season_year,match_no,user_name,points
2025,1,Bishan,200
```

## Seed Accounts
- Admin:
  - Email: `bishan@jackbuddies.local`
  - Password: `Password123!`
- Signup allowlist (first names):
  - `Sreekanth`, `Praveen`, `Prasad`, `Bishan`, `Sunny`, `Akil`, `Arun`, `Raghu`, `Naveen`, `Gopi`
  - Used as a reference list for admin matching; signup is still allowed for other names and remains pending admin approval.

## Scoring Rules (per season, editable in Admin)
- League: correct pick = 2
- Qualifier: correct pick = 3
- Eliminator: correct pick = 3
- Final: correct pick = 5

## How Scoring Works
Scoring is not stored as a single mutable total. It is a ledger of `points_events`.

- On match result entry, the app creates one event per user pick for that match.
- Correct pick gets stage points, wrong pick gets 0.
- Total points = sum of active (non-voided) events.
- If a winner changes or admin edits a completed match pick, prior auto events for that match are voided and regenerated.

Examples:
- League match (`2 points`):
  - User picked winner -> +2
  - User picked loser -> +0
- Final (`5 points`):
  - User picked winner -> +5
  - User picked loser -> +0

Manual corrections are stored as separate `manual_adjustment` events with explicit reason and admin attribution.

## Core Data Model
- `User` (`role`, `status` enums; approval metadata)
- `Season` (year, lock minutes)
- `Team`
- `Match` (stage/status enums, winner)
- `Pick` (unique per user+match)
- `PointsRule` (season+stage => points)
- `PointsEvent` (ledger entries, void metadata)
- `PickAuditLog` (admin pick edits)

## Quality Guards
- DB constraints and validations, including unique pick per user per match.
- Pundit policies on all app/admin surfaces.
- Pending-user access guard enforced globally.
- Recalculation utilities:
  - Single match: Admin matches page
  - Whole season: Admin dashboard/matches tools
