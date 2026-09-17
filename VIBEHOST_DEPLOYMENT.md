# Vibehost Deployment Guide

## Pre-Deployment Checklist

- [ ] GitHub repo created with all files
- [ ] Vibehost is online and accessible
- [ ] You have Vibehost access (Talabat account)

## Deployment Steps

### Step 1: Authenticate with Vibehost

Login to Vibehost
vibehost login

Enter your Talabat credentials

### Step 2: Create App

vibehost scaffold-app \
  --name "Rider Incentive" \
  --domain "rider-incentive-prod"

### Step 3: Configure Environment

Create .env file with:

DB_HOST=<vibehost-mysql-host>
DB_USER=incentive_user
DB_PASSWORD=<secure-password>
DB_NAME=rider_incentive_db
API_KEY=<secure-api-key>
FLASK_ENV=production

### Step 4: Deploy

vibehost deploy-app --domain rider-incentive-prod --commit "Initial deployment"

### Step 5: Monitor Deployment

vibehost check-deploy-status --domain rider-incentive-prod

Wait for status: "live"

## Access Your API

Once deployed:

https://rider-incentive-prod.vibehost.io

Health check:
curl https://rider-incentive-prod.vibehost.io/health

Get riders:
curl -H "X-API-Key: your-api-key" \
  https://rider-incentive-prod.vibehost.io/api/v1/riders

## Database Setup

Vibehost handles MySQL automatically. Your database will:
- Load schema automatically (rider_incentive_schema.sql)
- Load sample data automatically (populate_global_incentive_schemes.sql)
- Be accessible to the API

## Rollback

If needed, rollback to previous version:

vibehost deploy-app --domain rider-incentive-prod --commit "Rollback"

## Support

For Vibehost-specific issues:
- Check deployment logs: vibehost logs --domain rider-incentive-prod
- Contact Talabat DevOps team
