# Contributing to Rider Incentive System

## Getting Started

1. Clone the repo
```bash
git clone https://github.com/shahmeeraig-blip/rider-incentive.git
cd rider-incentive
```

2. Copy environment file
```bash
cp .env.example .env
```

3. Update `.env` with your values

DB_PASSWORD=your_password
API_KEY=your_api_key

4. Start the system
```bash
docker-compose build
docker-compose up -d
```

5. Verify it's running
```bash
curl http://localhost:5000/health
```

## Testing Endpoints

See `TESTING.md` for API testing examples.

## Project Structure
rider-incentive/
├── api_server.py # Flask API server
├── rider_incentive_schema.sql # Database schema
├── populate_global_incentive_schemes.sql # Sample data
├── requirements.txt # Python dependencies
├── docker-compose.yml # Docker configuration
├── Dockerfile # Container definition
├── .env.example # Environment template
├── .env # Local environment (not committed)
├── README.md # Project overview
├── CONTRIBUTING.md # This file
├── TESTING.md # API testing guide
├── DEPLOYMENT_GUIDE.md # Full deployment instructions
├── VIBEHOST_DEPLOYMENT.md # Vibehost-specific guide
└── PERFORMANCE_CHECKLIST.md # Pre-deployment checklist

## API Documentation

The API provides 15+ endpoints for:
- Rider management
- Quest management
- Enrollments and completions
- Analytics and leaderboards
- Payout processing

See `TESTING.md` for examples.

## Database

- MySQL 8.0
- 10 tables with relationships
- Automated schema loading via Docker

## Deployment

- **Local:** Docker Compose
- **Production:** Vibehost (see `VIBEHOST_DEPLOYMENT.md`)

## Support

For issues:
1. Check `DEPLOYMENT_GUIDE.md`
2. Review `TESTING.md` for endpoint examples
3. Check Docker logs: `docker-compose logs`
4. Contact the development team
