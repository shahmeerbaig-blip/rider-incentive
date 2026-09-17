# Rider Incentive/Quest System

Global incentive platform for Talabat riders across 7 platforms, 5 regions, with 24 sample riders and 20+ active quests.

## Features

- 10 MySQL tables with relationships
- REST API with 15+ endpoints
- Real-time analytics and leaderboards
- Tiered reward system (Bronze to Diamond)
- Global incentive schemes from major platforms

## Quick Start

### Local Development
```bash
docker-compose build
docker-compose up -d
curl http://localhost:5000/health
```

### Vibehost Deployment
See `VIBEHOST_DEPLOYMENT.md`

## API Endpoints

### Health & Status
- `GET /health` - Health check
- `GET /api/v1/status` - API status

### Riders
- `GET /api/v1/riders` - List all riders
- `GET /api/v1/riders/<id>` - Get specific rider
- `GET /api/v1/riders/<id>/stats` - Get rider stats

### Quests
- `GET /api/v1/quests` - List quests
- `GET /api/v1/quests/<id>` - Get specific quest
- `POST /api/v1/riders/<id>/enroll` - Enroll in quest
- `POST /api/v1/riders/<id>/quests/<id>/complete` - Complete quest

### Analytics
- `GET /api/v1/analytics/leaderboard` - Top riders
- `GET /api/v1/analytics/tiers` - Tier distribution
- `GET /api/v1/analytics/quests` - Quest performance

### Payouts
- `GET /api/v1/payouts/pending` - Pending payouts
- `POST /api/v1/payouts/<id>/process` - Process payout

## Database

- MySQL 8.0
- 10 tables with proper relationships
- 25+ indexes for performance
- 3 analytical views
- Sample data: 7 platforms, 24 riders, 20+ quests

## Documentation

- `MODEL_DOCUMENTATION.md` - Database schema details
- `INTEGRATION_EXAMPLES.md` - 6 real-world use cases
- `DEPLOYMENT_GUIDE.md` - Full deployment instructions
- `GLOBAL_INCENTIVE_SCHEMES_GUIDE.md` - Platform analysis
- `SETUP_INSTRUCTIONS.md` - Quick setup guide

## Technology Stack

- **Database:** MySQL 8.0
- **Backend:** Python Flask
- **Server:** Gunicorn/WSGI
- **Deployment:** Docker / Vibehost
- **API:** RESTful with rate limiting

## Environment Variables

See `.env.example` for required environment variables.

## Installation

1. Clone this repository
2. Copy `.env.example` to `.env`
3. Update `.env` with your values
4. Run `docker-compose build && docker-compose up -d`
5. Access API at `http://localhost:5000`

## Support

For issues or questions, see the documentation files or contact the development team.
