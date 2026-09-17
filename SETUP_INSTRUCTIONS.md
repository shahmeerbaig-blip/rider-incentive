# Rider Incentive/Quest Database - Setup Instructions

## Quick Start (5 minutes)

### Prerequisites
- MySQL 5.7+ or MySQL 8.0+
- MySQL client or workbench
- ~50MB disk space

### Step 1: Create Database
```bash
mysql -u root -p
```

```sql
CREATE DATABASE rider_incentive_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE rider_incentive_db;
```

### Step 2: Load Schema
```bash
mysql -u root -p rider_incentive_db < rider_incentive_schema.sql
```

### Step 3: Populate Global Data
```bash
mysql -u root -p rider_incentive_db < populate_global_incentive_schemes.sql
```

### Step 4: Verify Installation
```bash
mysql -u root -p rider_incentive_db
```

```sql
-- Check table count
SELECT COUNT(*) as table_count FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'rider_incentive_db';
-- Should return: 10 tables

-- Check rider count
SELECT COUNT(*) as riders FROM riders;
-- Should return: 24 riders

-- Check active quests
SELECT COUNT(*) as quests FROM quests WHERE status = 'active';
-- Should return: 20+ quests
```

---

## File Manifest

### Core Files (Required)

| File | Size | Purpose | Status |
|------|------|---------|--------|
| `rider_incentive_schema.sql` | 18 KB | Core database schema | ✅ Ready |
| `populate_global_incentive_schemes.sql` | 45 KB | Global data population | ✅ Ready |
| `MODEL_DOCUMENTATION.md` | 35 KB | Complete documentation | ✅ Ready |
| `GLOBAL_INCENTIVE_SCHEMES_GUIDE.md` | 32 KB | Platform-by-platform guide | ✅ Ready |

### Implementation Files (Optional)

| File | Language | Purpose |
|------|----------|---------|
| `implementation_guide.py` | Python | Database client library |

---

## Data Loaded

### Tiers (5)
- Bronze (Entry, 1.0x multiplier)
- Silver (Intermediate, 1.15x multiplier)
- Gold (Advanced, 1.35x multiplier)
- Platinum (Elite, 1.6x multiplier)
- Diamond (Legend, 2.0x multiplier)

### Platforms (7)
1. **Uber Eats** - 4 quests, North America/Global
2. **DoorDash** - 3 quests, North America
3. **Lyft** - 3 quests, North America
4. **Grab** - 3 quests, Southeast Asia
5. **Talabat** - 3 quests, Middle East
6. **Wolt** - 3 quests, Europe/Asia
7. **Deliveroo** - 3 quests, UK/Europe/Asia

### Riders (24)
- Middle East: 5 riders
- Southeast Asia: 4 riders
- Europe: 4 riders
- North America: 4 riders
- India: 4 riders

### Sample Data
- 200+ Active Quest Enrollments
- 150+ Quest Completions
- 150+ Reward Payouts
- $68,000+ Total Earnings

---

## Verification Checklist

After setup, run these queries to verify:

### 1. Schema Integrity
```sql
-- Check all tables exist
SELECT TABLE_NAME FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'rider_incentive_db' 
ORDER BY TABLE_NAME;
```

Expected tables:
- incentive_tiers
- riders
- quest_types
- quests
- quest_participants
- quest_completions
- reward_types
- reward_payouts
- rider_stats
- quest_feedback

### 2. Data Completeness
```sql
-- Tier count
SELECT COUNT(*) FROM incentive_tiers;
-- Expected: 5

-- Rider count
SELECT COUNT(*) FROM riders;
-- Expected: 24

-- Quest types
SELECT COUNT(*) FROM quest_types;
-- Expected: 24

-- Active quests
SELECT COUNT(*) FROM quests WHERE status = 'active';
-- Expected: 20+

-- Participants
SELECT COUNT(*) FROM quest_participants;
-- Expected: 200+

-- Completions
SELECT COUNT(*) FROM quest_completions;
-- Expected: 150+
```

### 3. Data Quality
```sql
-- Check for orphaned records
SELECT COUNT(*) as orphaned_participants
FROM quest_participants qp
WHERE NOT EXISTS (SELECT 1 FROM riders WHERE rider_id = qp.rider_id);
-- Expected: 0

-- Check earnings sanity
SELECT 
  MIN(total_earnings) as min_earnings,
  MAX(total_earnings) as max_earnings,
  AVG(total_earnings) as avg_earnings
FROM riders;
-- Expected: Min=480, Max=6840.50, Avg=~2847

-- Check rating ranges
SELECT COUNT(*) as invalid_ratings
FROM riders
WHERE average_rating < 0 OR average_rating > 5;
-- Expected: 0
```

---

## Sample Analytics Queries

### Top Performers by Tier
```sql
SELECT
  it.tier_name,
  COUNT(r.rider_id) as rider_count,
  AVG(r.total_earnings) as avg_earnings,
  AVG(r.average_rating) as avg_rating,
  SUM(r.total_quests_completed) as total_quests
FROM riders r
JOIN incentive_tiers it ON r.current_tier_id = it.tier_id
WHERE r.status = 'active'
GROUP BY it.tier_id, it.tier_name
ORDER BY it.tier_level DESC;
```

### Regional Performance
```sql
SELECT
  CASE
    WHEN rider_code LIKE 'RID_ME%' THEN 'Middle East'
    WHEN rider_code LIKE 'RID_SEA%' THEN 'Southeast Asia'
    WHEN rider_code LIKE 'RID_EU%' THEN 'Europe'
    WHEN rider_code LIKE 'RID_NA%' THEN 'North America'
    WHEN rider_code LIKE 'RID_IN%' THEN 'India'
  END as region,
  COUNT(*) as riders,
  AVG(total_earnings) as avg_earnings,
  AVG(average_rating) as avg_rating
FROM riders
WHERE status = 'active'
GROUP BY region
ORDER BY avg_earnings DESC;
```

### Quest Participation & Completion
```sql
SELECT
  q.quest_code,
  q.quest_name,
  COUNT(DISTINCT qp.rider_id) as participants,
  SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END) as completed,
  ROUND(100.0 * SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT qp.rider_id), 0), 2) as completion_rate
FROM quests q
LEFT JOIN quest_participants qp ON q.quest_id = qp.quest_id
WHERE q.status = 'active'
GROUP BY q.quest_id, q.quest_code, q.quest_name
ORDER BY completion_rate DESC;
```

### Monthly Earnings Summary
```sql
SELECT
  DATE_TRUNC(qc.completion_date, MONTH) as month,
  COUNT(DISTINCT qc.rider_id) as active_riders,
  COUNT(DISTINCT qc.completion_id) as total_completions,
  SUM(qc.reward_earned) as base_rewards,
  SUM(qc.tier_bonus_applied) as tier_bonuses,
  SUM(qc.reward_earned + qc.tier_bonus_applied) as total_rewards
FROM quest_completions qc
GROUP BY DATE_TRUNC(qc.completion_date, MONTH)
ORDER BY month DESC;
```

---

## Troubleshooting

### Issue: "Table doesn't exist" after schema load
**Solution:** Verify schema file executed completely
```bash
mysql -u root -p rider_incentive_db < rider_incentive_schema.sql 2>&1 | grep -i error
```

### Issue: Foreign key constraint error
**Solution:** Ensure tables loaded in correct order
```sql
SET FOREIGN_KEY_CHECKS=0;
-- Then reload schema
SET FOREIGN_KEY_CHECKS=1;
```

### Issue: Duplicate key error on population
**Solution:** Clear data first
```sql
TRUNCATE TABLE quest_feedback;
TRUNCATE TABLE reward_payouts;
TRUNCATE TABLE quest_completions;
TRUNCATE TABLE quest_participants;
TRUNCATE TABLE rider_stats;
TRUNCATE TABLE riders;
TRUNCATE TABLE quests;
TRUNCATE TABLE quest_types;
TRUNCATE TABLE incentive_tiers;
TRUNCATE TABLE reward_types;
```

### Issue: "Access denied for user 'root'@'localhost'"
**Solution:** Check MySQL is running and password is correct
```bash
mysql -u root -p -h localhost -e "SELECT VERSION();"
```

---

## Next Steps

1. **Load Python Client**
   ```bash
   pip install mysql-connector-python pandas
   python implementation_guide.py
   ```

2. **Build Application Layer**
   - Use Python/Node.js client to query database
   - Implement real-time updates
   - Build rider dashboard

3. **Analytics & BI**
   - Connect to Tableau/Power BI
   - Create real-time dashboards
   - Monitor KPIs

4. **API Development**
   - Build REST API layer
   - Implement GraphQL endpoints
   - Add authentication/authorization

---

## Support & Maintenance

### Regular Maintenance Tasks

**Daily:**
- Monitor active quest participation
- Process pending payouts
- Alert on anomalies

**Weekly:**
- Recalculate rider tier eligibility
- Archive completed quests
- Generate performance reports

**Monthly:**
- Full database backup
- Performance optimization
- Tier promotion batches

### Backup Strategy
```bash
# Backup
mysqldump -u root -p rider_incentive_db > backup_$(date +%Y%m%d).sql

# Restore
mysql -u root -p rider_incentive_db < backup_20260912.sql
```

---

## Contact & Documentation

- **Schema Documentation:** See `MODEL_DOCUMENTATION.md`
- **Global Schemes:** See `GLOBAL_INCENTIVE_SCHEMES_GUIDE.md`
- **Implementation:** See `implementation_guide.py`
- **Database Version:** 1.0
- **Last Updated:** 2026-09-12

---

*Setup completed successfully! 🚀*
