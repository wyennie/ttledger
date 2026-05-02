# Tabletop Ledger

A Rails app for running tabletop RPG campaigns with AI-assisted prep — manage campaigns, characters, entities (NPCs, locations, factions, etc.), session pages, and chats, and import existing material from PDFs.

## Stack

- Rails 8 on Ruby 3.3.11, Hotwire (Turbo + Stimulus), Propshaft, importmap
- PostgreSQL for the primary DB; Solid Queue / Cache / Cable on SQLite
- Anthropic and OpenAI APIs for PDF expansion and draft generation
- RSpec, FactoryBot, Capybara
- Kamal for deployment (`config/deploy.yml`)

## Local development

See [LOCAL_DEV.md](LOCAL_DEV.md) for the full start/stop guide. Short version:

```bash
docker compose up -d db   # Postgres on 127.0.0.1:5432
bin/dev                   # Rails on http://localhost:3000
```

## Tests

```bash
bundle exec rspec
```
