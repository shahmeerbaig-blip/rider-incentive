#!/bin/bash

# Rider Incentive API Test Script
# Tests all major endpoints

API_URL="http://localhost:5000"
API_KEY="dev-api-key-123"

echo "================================"
echo "Rider Incentive API Test Suite"
echo "================================"
echo ""

# Health Check
echo "1. Health Check"
echo "   GET /health"
curl -s $API_URL/health | python -m json.tool
echo ""

# API Status
echo "2. API Status"
echo "   GET /api/v1/status"
curl -s $API_URL/api/v1/status | python -m json.tool
echo ""

# Get Riders
echo "3. List Riders"
echo "   GET /api/v1/riders (limit 5)"
curl -s -H "X-API-Key: $API_KEY" "$API_URL/api/v1/riders?limit=5" | python -m json.tool | head -50
echo ""

# Get Rider Details
echo "4. Get Specific Rider"
echo "   GET /api/v1/riders/1"
curl -s -H "X-API-Key: $API_KEY" $API_URL/api/v1/riders/1 | python -m json.tool | head -30
echo ""

# Get Active Quests
echo "5. List Active Quests"
echo "   GET /api/v1/quests"
curl -s -H "X-API-Key: $API_KEY" $API_URL/api/v1/quests | python -m json.tool | head -50
echo ""

# Get Leaderboard
echo "6. Get Leaderboard"
echo "   GET /api/v1/analytics/leaderboard (limit 5)"
curl -s -H "X-API-Key: $API_KEY" "$API_URL/api/v1/analytics/leaderboard?limit=5" | python -m json.tool | head -50
echo ""

# Get Tier Distribution
echo "7. Get Tier Distribution"
echo "   GET /api/v1/analytics/tiers"
curl -s -H "X-API-Key: $API_KEY" $API_URL/api/v1/analytics/tiers | python -m json.tool
echo ""

# Get Quest Analytics
echo "8. Get Quest Performance"
echo "   GET /api/v1/analytics/quests"
curl -s -H "X-API-Key: $API_KEY" $API_URL/api/v1/analytics/quests | python -m json.tool | head -50
echo ""

echo "================================"
echo "Test Suite Complete"
echo "================================"
