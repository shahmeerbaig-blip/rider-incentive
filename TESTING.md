# API Testing Guide

## Quick Start

All examples assume:
- API running on `http://localhost:5000`
- API key: `dev-api-key-123` (from `.env`)

Replace with your actual values.

## Health Check

Verify the API is running:

```bash
curl http://localhost:5000/health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2026-09-18T...",
  "version": "1.0.0"
}
```

## API Status

Get system status and statistics:

```bash
curl http://localhost:5000/api/v1/status
```

## Rider Endpoints

### List All Riders

```bash
curl -H "X-API-Key: dev-api-key-123" \
  http://localhost:5000/api/v1/riders
```

With pagination:
```bash
curl -H "X-API-Key: dev-api-key-123" \
  "http://localhost:5000/api/v1/riders?page=1&limit=10"
```

### Get Specific Rider

```bash
curl -H "X-API-Key: dev-api-key-123" \
  http://localhost:5000/api/v1/riders/1
```

### Get Rider Statistics

```bash
curl -H "X-API-Key: dev-api-key-123" \
  http://localhost:5000/api/v1/riders/1/stats
```

## Quest Endpoints

### List Active Quests

```bash
curl -H "X-API-Key: dev-api-key-123" \
  http://localhost:5000/api/v1/quests
```

Filter by difficulty:
```bash
curl -H "X-API-Key: dev-api-key-123" \
  "http://localhost:5000/api/v1/quests?status=active&difficulty=medium"
```

### Get Specific Quest

```bash
curl -H "X-API-Key: dev-api-key-123" \
  http://localhost:5000/api/v1/quests/1
```

## Enrollment & Completion

### Enroll Rider in Quest

```bash
curl -X POST \
  -H "X-API-Key: dev-api-key-123" \
  -H "Content-Type: application/json" \
  -d '{"quest_id": 1}' \
  http://localhost:5000/api/v1/riders/1/enroll
```

### Complete Quest

```bash
curl -X POST \
  -H "X-API-Key: dev-api-key-123" \
  -H "Content-Type: application/json" \
  -d '{
    "quality_rating": 5,
    "completion_time_hours": 1.5
  }' \
  http://localhost:5000/api/v1/riders/1/quests/1/complete
```

## Analytics Endpoints

### Get Leaderboard

```bash
curl -H "X-API-Key: dev-api-key-123" \
  http://localhost:5000/api/v1/analytics/leaderboard
```

Limit results:
```bash
curl -H "X-API-Key: dev-api-key-123" \
  "http://localhost:5000/api/v1/analytics/leaderboard?limit=50"
```

### Get Tier Distribution

```bash
curl -H "X-API-Key: dev-api-key-123" \
  http://localhost:5000/api/v1/analytics/tiers
```

### Get Quest Performance

```bash
curl -H "X-API-Key: dev-api-key-123" \
  http://localhost:5000/api/v1/analytics/quests
```

## Payout Endpoints

### Get Pending Payouts

```bash
curl -H "X-API-Key: dev-api-key-123" \
  http://localhost:5000/api/v1/payouts/pending
```

### Process Payout

```bash
curl -X POST \
  -H "X-API-Key: dev-api-key-123" \
  http://localhost:5000/api/v1/payouts/1/process
```

## Pretty Print JSON

Add `| python -m json.tool` to any curl command:

```bash
curl -H "X-API-Key: dev-api-key-123" \
  http://localhost:5000/api/v1/riders | python -m json.tool
```

## Troubleshooting

### API Not Responding

```bash
# Check if running
docker-compose ps

# Check logs
docker-compose logs api

# Restart
docker-compose restart api
```

### Database Connection Error

```bash
# Check MySQL
docker-compose logs mysql

# Verify credentials in .env
cat .env
```

### Invalid API Key

Ensure API key matches `.env`:
```bash
grep API_KEY .env
```

## Performance Notes

- Expected response time: < 200ms
- Database queries: < 100ms
- Rate limit: 100 requests/hour per IP
