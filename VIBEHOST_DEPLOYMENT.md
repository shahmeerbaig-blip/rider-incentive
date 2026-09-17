# Vibehost Deployment Guide

## Pre-Deployment Checklist

- [ ] GitHub repo created with all files
- [ ] Vibehost is online and accessible
- [ ] You have Vibehost access (Talabat account)

## Deployment Steps

### Step 1: Authenticate with Vibehost
```bash
# Login to Vibehost
vibehost login
# Enter your Talabat credentials
```

### Step 2: Create App
```bash
vibehost scaffold-app \
  --name "Rider Incentive" \
  --domain "rider-incentive-prod"
```

### Step 3: Configure Environment
Create `.env` file with:
