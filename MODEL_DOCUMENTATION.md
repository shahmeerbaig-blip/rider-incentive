# Rider Incentive/Quest Model - Complete Documentation

## Table of Contents
1. [Overview](#overview)
2. [Entity Descriptions](#entity-descriptions)
3. [Data Relationships](#data-relationships)
4. [Key Queries](#key-queries)
5. [Implementation Examples](#implementation-examples)
6. [Analytics & Reporting](#analytics--reporting)
7. [Best Practices](#best-practices)

---

## Overview

The **Rider Incentive/Quest Model** is a comprehensive gamification system designed to:
- Track rider participation in delivery quests
- Manage tiered incentive structures
- Calculate and distribute rewards
- Monitor performance metrics and ratings
- Provide analytics for business intelligence

### Core Principles

1. **Gamification**: Quests are time-bound challenges with varying difficulty levels
2. **Tiered Rewards**: Rider tier determines bonus multipliers on rewards
3. **Performance Tracking**: Every completion is rated and tracked
4. **Fairness**: Transparent reward calculation with documented tier benefits
5. **Scalability**: Designed for thousands of riders and quests

---

## Entity Descriptions

### 1. INCENTIVE_TIERS
Defines performance-based tier levels for riders. Each tier represents a milestone that unlocks better rewards.

**Key Fields:**
- `tier_id`: Primary key
- `tier_name`: Tier designation (Rookie, Expert, Master, Legend)
- `tier_level`: Numeric level (1-4 typically)
- `min_quests_completed`: Minimum quests to achieve this tier
- `min_rating`: Minimum average rating required
- `bonus_multiplier`: Reward multiplier (1.0x to 2.0x)
- `quest_priority`: Quest access priority

**Example Tiers:**
```
Rookie:    0 quests, 0.0 rating, 1.0x multiplier
Expert:    25 quests, 4.2 rating, 1.25x multiplier
Master:    100 quests, 4.6 rating, 1.5x multiplier
Legend:    500 quests, 4.8 rating, 2.0x multiplier
```

### 2. RIDERS
Core profile information for all delivery riders.

**Key Fields:**
- `rider_id`: Primary key
- `rider_code`: Unique identifier (RID001, RID002, etc.)
- `first_name`, `last_name`: Rider identity
- `email`, `phone_number`: Contact information
- `current_tier_id`: Foreign key to incentive_tiers
- `status`: active, inactive, suspended, onboarded
- `join_date`: When rider started
- `total_earnings`: Cumulative earnings (denormalized for performance)
- `total_quests_completed`: Count of completed quests
- `average_rating`: Average quality rating (1-5 stars)

**Indexes:**
- `idx_status`: For filtering by rider status
- `idx_tier`: For tier-based queries
- `idx_earnings`: For leaderboards
- `idx_quests_completed`: For performance rankings

### 3. QUEST_TYPES
Categorizes quests by type for better organization and metrics.

**Key Fields:**
- `quest_type_id`: Primary key
- `type_name`: Category name (Delivery Challenge, Time Trial, Quality Quest, etc.)
- `base_reward`: Default reward for this type
- `difficulty_level`: easy, medium, hard, expert

### 4. QUESTS
Individual quest definitions with rewards and participation rules.

**Key Fields:**
- `quest_id`: Primary key
- `quest_code`: Unique code (QST001, QST002, etc.)
- `quest_name`: Human-readable quest title
- `quest_type_id`: Foreign key to quest_types
- `base_reward_amount`: Base reward in currency
- `bonus_reward`: Additional reward if conditions met
- `min_tier_requirement_id`: Minimum tier to participate
- `max_participants`: Limit on participation (-1 = unlimited)
- `start_date`, `end_date`: Quest availability window
- `status`: draft, active, paused, completed, cancelled
- `completion_criteria`: Rules for completion
- `required_activities`: Number of deliveries/activities needed

**Example Quests:**
```
QST001: Weekend Rush - 50 Orders
  - Difficulty: Medium
  - Base Reward: $50
  - Bonus: $10 if completed in 3 days
  - Min Tier: Rookie
  - Max Participants: 1000

QST002: Speed Demon - 30min Delivery
  - Difficulty: Hard
  - Base Reward: $75
  - Bonus: $25 if rated 5 stars
  - Min Tier: Expert
  - Max Participants: 100
```

### 5. QUEST_PARTICIPANTS
Junction table linking riders to quests.

**Key Fields:**
- `participant_id`: Primary key
- `rider_id`: Foreign key to riders
- `quest_id`: Foreign key to quests
- `participation_status`: enrolled, in_progress, completed, abandoned, failed
- `enrollment_date`: When rider joined the quest
- `progress_percentage`: 0-100 completion progress
- `attempts`: Number of completion attempts

**Status Flow:**
```
enrolled → in_progress → completed
                      ↘ failed
                      ↘ abandoned
```

### 6. QUEST_COMPLETIONS
Records individual quest completion events.

**Key Fields:**
- `completion_id`: Primary key
- `participant_id`: Foreign key
- `rider_id`: Foreign key to riders
- `quest_id`: Foreign key to quests
- `completion_date`: Timestamp of completion
- `completion_time_hours`: Time taken to complete
- `quality_rating`: 1-5 star quality assessment
- `proof_document_url`: URL to completion proof
- `reward_earned`: Base reward amount
- `tier_bonus_applied`: Bonus from tier multiplier

**Reward Calculation:**
```
total_reward = (base_reward + bonus_reward) × tier_bonus_multiplier × streak_multiplier
```

### 7. REWARD_TYPES
Defines types of rewards available in the system.

**Key Fields:**
- `reward_type_id`: Primary key
- `type_name`: Reward type (Cash, Bonus, Badge, Voucher)
- `reward_category`: cash, bonus, badge, voucher, special

### 8. REWARD_PAYOUTS
Tracks all reward distributions.

**Key Fields:**
- `payout_id`: Primary key
- `rider_id`: Foreign key to riders
- `quest_id`: Optional foreign key
- `completion_id`: Optional foreign key
- `reward_type_id`: Foreign key to reward_types
- `reward_amount`: Amount to pay
- `payout_status`: pending, approved, processed, failed, cancelled
- `payout_date`: When payment occurred
- `payment_method`: wallet, bank_transfer, voucher
- `transaction_id`: External payment system ID

**Status Flow:**
```
pending → approved → processed
                  ↘ failed
                  ↘ cancelled
```

### 9. RIDER_STATS
Denormalized aggregated metrics for performance queries.

**Key Fields:**
- `stat_id`: Primary key
- `rider_id`: Unique foreign key to riders
- `total_quests_enrolled`: Quest enrollments
- `total_quests_completed`: Completed quests
- `total_quests_abandoned`: Abandoned quests
- `completion_rate`: Percentage of completed vs. enrolled
- `average_completion_time_hours`: Avg time to complete
- `average_quality_rating`: Avg quality rating
- `total_earnings`: Cumulative earnings
- `earnings_this_month`: MTD earnings
- `earnings_this_week`: WTD earnings
- `consecutive_completed_quests`: Current streak
- `streak_bonus_multiplier`: Active streak bonus

**Purpose:** Performance and leaderboard queries without complex JOINs

### 10. QUEST_FEEDBACK
Captures rider feedback on individual quests.

**Key Fields:**
- `feedback_id`: Primary key
- `completion_id`: Foreign key
- `rider_id`: Foreign key
- `difficulty_rating`: 1-5 difficulty assessment
- `reward_fairness_rating`: 1-5 fairness assessment
- `enjoyment_rating`: 1-5 enjoyment rating
- `feedback_text`: Free-form comments
- `would_repeat`: Boolean - would rider do this quest again

---

## Data Relationships

### Primary Relationships

```
RIDERS (1) ──→ (N) QUEST_PARTICIPANTS
  ├─ A rider can participate in many quests
  └─ Tracks rider's quest history

QUESTS (1) ──→ (N) QUEST_PARTICIPANTS
  ├─ A quest can have many participating riders
  └─ Tracks quest popularity

QUEST_PARTICIPANTS (1) ──→ (N) QUEST_COMPLETIONS
  ├─ A participation can have multiple attempts
  └─ Tracks completion history per participation

QUEST_COMPLETIONS (1) ──→ (N) REWARD_PAYOUTS
  ├─ A completion triggers reward(s)
  └─ Tracks reward distribution

RIDERS (1) ──→ (1) RIDER_STATS
  ├─ Each rider has one stats record
  └─ Maintains aggregated metrics

RIDERS (N) ──→ (1) INCENTIVE_TIERS
  ├─ Many riders per tier
  └─ Tracks rider tier membership
```

### Integrity Constraints

- **Cascading Deletes**: Removing a rider cascades to all related records
- **Unique Constraints**: Prevents duplicate enrollments (rider_id, quest_id)
- **Foreign Keys**: Enforce referential integrity across entities
- **Check Constraints**: Ratings must be 1-5, percentages 0-100

---

## Key Queries

### 1. Enroll a Rider in a Quest

```sql
INSERT INTO quest_participants 
(rider_id, quest_id, participation_status, enrollment_date)
VALUES (
  (SELECT rider_id FROM riders WHERE rider_code = 'RID001'),
  (SELECT quest_id FROM quests WHERE quest_code = 'QST001'),
  'enrolled',
  NOW()
);
```

### 2. Record a Completed Quest

```sql
DELIMITER $$

CREATE PROCEDURE record_quest_completion (
  IN p_rider_code VARCHAR(20),
  IN p_quest_code VARCHAR(30),
  IN p_quality_rating INT,
  IN p_completion_hours DECIMAL(10,2)
)
BEGIN
  DECLARE v_rider_id INT;
  DECLARE v_quest_id INT;
  DECLARE v_participant_id INT;
  DECLARE v_base_reward DECIMAL(10,2);
  DECLARE v_tier_multiplier DECIMAL(3,2);
  DECLARE v_total_reward DECIMAL(10,2);
  
  -- Get IDs
  SELECT rider_id INTO v_rider_id FROM riders WHERE rider_code = p_rider_code;
  SELECT quest_id, base_reward_amount INTO v_quest_id, v_base_reward 
    FROM quests WHERE quest_code = p_quest_code;
  
  -- Get participant record
  SELECT participant_id INTO v_participant_id
    FROM quest_participants 
    WHERE rider_id = v_rider_id AND quest_id = v_quest_id;
  
  -- Get tier multiplier
  SELECT bonus_multiplier INTO v_tier_multiplier
    FROM riders r
    JOIN incentive_tiers it ON r.current_tier_id = it.tier_id
    WHERE r.rider_id = v_rider_id;
  
  -- Calculate reward
  SET v_total_reward = v_base_reward * v_tier_multiplier;
  
  -- Record completion
  INSERT INTO quest_completions 
  (participant_id, rider_id, quest_id, completion_date, completion_time_hours, 
   quality_rating, reward_earned, tier_bonus_applied)
  VALUES (
    v_participant_id, v_rider_id, v_quest_id, NOW(), p_completion_hours,
    p_quality_rating, v_base_reward, (v_base_reward * (v_tier_multiplier - 1))
  );
  
  -- Create payout
  INSERT INTO reward_payouts 
  (rider_id, completion_id, quest_id, reward_type_id, reward_amount, 
   payout_status, payment_method)
  SELECT
    v_rider_id,
    (SELECT completion_id FROM quest_completions 
     WHERE participant_id = v_participant_id ORDER BY completion_date DESC LIMIT 1),
    v_quest_id,
    (SELECT reward_type_id FROM reward_types WHERE type_name = 'Cash' LIMIT 1),
    v_total_reward,
    'pending',
    'wallet';
  
  -- Update participation status
  UPDATE quest_participants
  SET participation_status = 'completed'
  WHERE participant_id = v_participant_id;
  
  -- Update rider stats
  UPDATE riders
  SET total_quests_completed = total_quests_completed + 1,
      total_earnings = total_earnings + v_total_reward
  WHERE rider_id = v_rider_id;
END$$

DELIMITER ;
```

### 3. Promote Rider to Next Tier

```sql
DELIMITER $$

CREATE PROCEDURE promote_rider_tier (
  IN p_rider_id INT
)
BEGIN
  DECLARE v_current_tier INT;
  DECLARE v_completed_quests INT;
  DECLARE v_avg_rating DECIMAL(3,2);
  DECLARE v_next_tier INT;
  
  -- Get current status
  SELECT current_tier_id INTO v_current_tier FROM riders WHERE rider_id = p_rider_id;
  SELECT total_quests_completed, average_rating 
    INTO v_completed_quests, v_avg_rating FROM riders WHERE rider_id = p_rider_id;
  
  -- Find next tier they qualify for
  SELECT tier_id INTO v_next_tier
  FROM incentive_tiers
  WHERE tier_level > (SELECT tier_level FROM incentive_tiers WHERE tier_id = v_current_tier)
    AND min_quests_completed <= v_completed_quests
    AND min_rating <= v_avg_rating
  ORDER BY tier_level ASC
  LIMIT 1;
  
  -- If eligible, promote
  IF v_next_tier IS NOT NULL THEN
    UPDATE riders SET current_tier_id = v_next_tier WHERE rider_id = p_rider_id;
    INSERT INTO rider_stats_history (rider_id, old_tier, new_tier, promotion_date)
    VALUES (p_rider_id, v_current_tier, v_next_tier, NOW());
  END IF;
END$$

DELIMITER ;
```

### 4. Get Top Performers Leaderboard

```sql
SELECT
  r.rider_code,
  CONCAT(r.first_name, ' ', r.last_name) as rider_name,
  it.tier_name,
  rs.total_quests_completed,
  rs.completion_rate,
  rs.average_quality_rating,
  rs.total_earnings,
  RANK() OVER (ORDER BY rs.total_earnings DESC) as earnings_rank,
  RANK() OVER (ORDER BY rs.average_quality_rating DESC) as quality_rank
FROM riders r
JOIN incentive_tiers it ON r.current_tier_id = it.tier_id
JOIN rider_stats rs ON r.rider_id = rs.rider_id
WHERE r.status = 'active'
ORDER BY rs.total_earnings DESC
LIMIT 20;
```

### 5. Get Active Quests with Participation Summary

```sql
SELECT
  q.quest_code,
  q.quest_name,
  q.difficulty_level,
  q.base_reward_amount,
  COUNT(DISTINCT qp.rider_id) as total_participants,
  SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END) as completed,
  SUM(CASE WHEN qp.participation_status = 'in_progress' THEN 1 ELSE 0 END) as in_progress,
  SUM(CASE WHEN qp.participation_status = 'abandoned' THEN 1 ELSE 0 END) as abandoned,
  ROUND(100.0 * SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END) 
        / NULLIF(COUNT(DISTINCT qp.rider_id), 0), 2) as completion_rate_pct
FROM quests q
LEFT JOIN quest_participants qp ON q.quest_id = qp.quest_id
WHERE q.status = 'active' 
  AND q.start_date <= NOW()
  AND q.end_date >= NOW()
GROUP BY q.quest_id, q.quest_code, q.quest_name, q.difficulty_level, q.base_reward_amount
ORDER BY completion_rate_pct DESC;
```

---

## Implementation Examples

### Scenario 1: Launch a New Quest

```sql
-- 1. Create quest type (if needed)
INSERT INTO quest_types (type_name, base_reward, difficulty_level)
VALUES ('Time Trial', 75.00, 'hard');

-- 2. Create the quest
INSERT INTO quests 
(quest_code, quest_name, quest_type_id, description, 
 base_reward_amount, bonus_reward, difficulty_level,
 min_tier_requirement_id, max_participants,
 start_date, end_date, status, completion_criteria, required_activities)
VALUES (
  'QST_SPEED_001',
  'Speed Demon - 30min Deliveries',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Time Trial'),
  'Complete 10 deliveries in under 30 minutes each',
  75.00,  -- Base reward
  25.00,  -- Bonus if 5-star rated
  'hard',
  (SELECT tier_id FROM incentive_tiers WHERE tier_name = 'Expert'),  -- Min Expert tier
  500,  -- Max participants
  DATE_ADD(NOW(), INTERVAL 7 DAY),  -- Start in 7 days
  DATE_ADD(NOW(), INTERVAL 14 DAY),  -- End in 14 days
  'active',
  '10 deliveries completed, each under 30 minutes',
  10
);

-- 3. Auto-enroll eligible riders (Expert+ tier)
INSERT INTO quest_participants (rider_id, quest_id, participation_status, enrollment_date)
SELECT 
  r.rider_id,
  (SELECT quest_id FROM quests WHERE quest_code = 'QST_SPEED_001'),
  'enrolled',
  NOW()
FROM riders r
JOIN incentive_tiers it ON r.current_tier_id = it.tier_id
WHERE r.status = 'active' 
  AND it.tier_level >= (
    SELECT tier_level FROM incentive_tiers 
    WHERE tier_id = (SELECT min_tier_requirement_id FROM quests WHERE quest_code = 'QST_SPEED_001')
  )
LIMIT 500;  -- Honor max_participants
```

### Scenario 2: Calculate Monthly Earnings Report

```sql
SELECT
  DATE_TRUNC(qc.completion_date, MONTH) as month,
  COUNT(DISTINCT qc.rider_id) as active_riders,
  COUNT(DISTINCT qc.completion_id) as total_completions,
  SUM(qc.reward_earned) as base_rewards,
  SUM(qc.tier_bonus_applied) as tier_bonuses,
  SUM(qc.reward_earned + qc.tier_bonus_applied) as total_rewards,
  AVG(qc.reward_earned) as avg_reward_per_completion,
  AVG(qc.quality_rating) as avg_quality_rating
FROM quest_completions qc
WHERE qc.completion_date >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
GROUP BY DATE_TRUNC(qc.completion_date, MONTH)
ORDER BY month DESC;
```

### Scenario 3: Identify At-Risk Riders

```sql
SELECT
  r.rider_code,
  CONCAT(r.first_name, ' ', r.last_name) as rider_name,
  it.tier_name,
  rs.total_quests_completed,
  rs.completion_rate,
  MAX(qc.completion_date) as last_activity,
  DATEDIFF(NOW(), MAX(qc.completion_date)) as days_inactive,
  rs.total_earnings,
  CASE 
    WHEN DATEDIFF(NOW(), MAX(qc.completion_date)) > 30 THEN 'HIGH RISK'
    WHEN DATEDIFF(NOW(), MAX(qc.completion_date)) > 14 THEN 'MEDIUM RISK'
    ELSE 'LOW RISK'
  END as risk_level
FROM riders r
JOIN incentive_tiers it ON r.current_tier_id = it.tier_id
JOIN rider_stats rs ON r.rider_id = rs.rider_id
LEFT JOIN quest_completions qc ON r.rider_id = qc.rider_id
WHERE r.status = 'active'
GROUP BY r.rider_id, r.rider_code, r.first_name, r.last_name, 
         it.tier_name, rs.total_quests_completed, rs.completion_rate, rs.total_earnings
HAVING DATEDIFF(NOW(), MAX(qc.completion_date)) > 7
ORDER BY risk_level, days_inactive DESC;
```

---

## Analytics & Reporting

### Available Views

1. **v_active_quests**: Summarizes active quests with participation metrics
2. **v_rider_performance**: Individual rider performance snapshot
3. **v_earnings_dashboard**: Monthly earnings trends and distributions

### Common Reports

**Daily Operations:**
- Active rider count
- Quests launched today
- Completions in last 24 hours
- Payouts pending approval

**Weekly Management:**
- Top 20 performers by earnings
- Completion rates by quest difficulty
- New riders onboarded
- Tier promotions

**Monthly Strategic:**
- Total rewards distributed
- Rider engagement trends
- Quest popularity analysis
- Revenue impact analysis

---

## Best Practices

### Data Entry
1. **Validation**: Always validate tier eligibility before enrollment
2. **Timestamps**: Use UTC timestamps for all operations
3. **Atomic Operations**: Use transactions for multi-table updates
4. **Audit Trail**: Consider adding audit tables for compliance

### Performance
1. **Indexing**: Keep indexes on frequently queried columns (status, tier, dates)
2. **Aggregation**: Use RIDER_STATS table instead of JOINing all tables
3. **Partitioning**: Consider monthly partitioning of quest_completions for large systems
4. **Caching**: Cache leaderboards and tier requirements

### Data Integrity
1. **Constraints**: Use CHECK constraints for rating ranges (1-5)
2. **Unique Keys**: Enforce (rider_id, quest_id) uniqueness in quest_participants
3. **Referential**: Maintain foreign key constraints
4. **Transactions**: Wrap multi-statement operations in transactions

### Maintenance
1. **Regular Updates**: Update RIDER_STATS nightly via batch job
2. **Tier Promotions**: Run promotion logic weekly based on achievement criteria
3. **Payouts**: Process pending payouts daily
4. **Archival**: Archive old quest data quarterly

---

## Appendix: Setup Instructions

### 1. Create Database
```sql
CREATE DATABASE rider_incentive_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE rider_incentive_db;
```

### 2. Load Schema
```bash
mysql -u root -p rider_incentive_db < rider_incentive_schema.sql
```

### 3. Initialize Tier Data
```sql
INSERT INTO incentive_tiers (tier_name, tier_level, min_quests_completed, min_rating, bonus_multiplier)
VALUES 
('Rookie', 1, 0, 0.0, 1.0),
('Expert', 2, 25, 4.2, 1.25),
('Master', 3, 100, 4.6, 1.5),
('Legend', 4, 500, 4.8, 2.0);
```

### 4. Initialize Reward Types
```sql
INSERT INTO reward_types (type_name, reward_category, description)
VALUES
('Cash Reward', 'cash', 'Direct cash payment'),
('Bonus', 'bonus', 'Performance bonus'),
('Badge', 'badge', 'Achievement badge'),
('Voucher', 'voucher', 'Store credit');
```

### 5. Test Connection
```sql
SELECT COUNT(*) as tier_count FROM incentive_tiers;
-- Should return 4
```

---

*Last Updated: 2026-09-12*
*Model Version: 1.0*
