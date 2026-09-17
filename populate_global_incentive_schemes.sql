-- ============================================================================
-- RIDER INCENTIVE/QUEST MODEL - GLOBAL INCENTIVE SCHEMES POPULATION
-- Real-world incentive programs from companies around the world
-- ============================================================================

-- ============================================================================
-- SECTION 1: INCENTIVE TIERS (Global Standards)
-- Based on Uber Pro, Lyft Rewards, and DoorDash Dasher Premier
-- ============================================================================

-- Clear existing data (optional)
-- TRUNCATE TABLE riders;
-- TRUNCATE TABLE quests;
-- TRUNCATE TABLE quest_types;
-- TRUNCATE TABLE incentive_tiers;

-- Insert Global Standard Tiers
INSERT INTO incentive_tiers (tier_name, tier_level, min_quests_completed, min_rating, bonus_multiplier, quest_priority, description)
VALUES
('Bronze', 1, 0, 0.0, 1.0, 3, 'Entry level - Standard earnings'),
('Silver', 2, 25, 3.8, 1.15, 2, 'Intermediate - 15% bonus multiplier'),
('Gold', 3, 100, 4.2, 1.35, 2, 'Advanced - 35% bonus, priority access'),
('Platinum', 4, 250, 4.5, 1.6, 1, 'Elite - 60% bonus, exclusive quests'),
('Diamond', 5, 500, 4.7, 2.0, 1, 'Legend - 2x earnings, VIP status');

-- ============================================================================
-- SECTION 2: QUEST TYPES (From Global Platforms)
-- ============================================================================

INSERT INTO quest_types (type_name, base_reward, difficulty_level, description)
VALUES
-- Uber Eats Style Quests
('Uber Quest', 45.00, 'medium', 'Complete N deliveries for flat bonus'),
('Uber Boost', 30.00, 'easy', 'Earn multiplier on orders in specific zones'),
('Uber Consecutive', 25.00, 'hard', 'Earn bonuses for accepting consecutive orders'),

-- DoorDash Dasher Style Quests
('DoorDash Peak Bonus', 50.00, 'medium', 'Extra earnings during peak hours'),
('DoorDash Challenge', 75.00, 'hard', 'Complete orders meeting specific criteria'),
('DoorDash Platinum Bonus', 100.00, 'expert', 'Exclusive for top-tier dashers'),

-- Lyft Rewards Style Quests
('Lyft Challenge', 55.00, 'medium', 'Complete rides in specified zones'),
('Lyft Streak Bonus', 40.00, 'medium', 'Bonus for accepting consecutive rides'),
('Lyft Destination Bonus', 30.00, 'easy', 'Complete trips to specific destinations'),

-- Grab Incentives (Southeast Asia)
('Grab Rush Hour Bonus', 35.00, 'medium', 'Extra earnings during peak demand'),
('Grab Loyalty Reward', 60.00, 'medium', 'Bonus for consistent daily activity'),
('Grab Perfect Rating', 80.00, 'hard', 'Reward for maintaining 5-star rating'),

-- Talabat Regional
('Talabat Peak Hours', 40.00, 'easy', 'Bonus for deliveries 11am-2pm, 6pm-9pm'),
('Talabat Weekend Rush', 75.00, 'hard', 'Complete 50 orders Friday-Sunday'),
('Talabat Tip Multiplier', 50.00, 'medium', 'Talabat matches rider tips 1:1'),

-- Wolt (Europe/Global)
('Wolt Hot Spot', 45.00, 'medium', 'Complete orders in high-demand areas'),
('Wolt Rating Bonus', 70.00, 'hard', 'Bonus for maintaining 4.8+ rating'),
('Wolt Surge Surge', 55.00, 'medium', 'Earnings multiplier during surge pricing'),

-- Deliveroo (UK/Europe/Asia)
('Deliveroo Boost', 50.00, 'medium', 'Earnings multiplier by time and location'),
('Deliveroo Guaranteed', 90.00, 'medium', 'Guaranteed minimum per order'),
('Deliveroo High Demand', 65.00, 'hard', 'Extra bonus during peak periods'),

-- Regional/Generic Quests
('Quality Assurance', 85.00, 'hard', 'Complete deliveries with photo proof'),
('Speed Challenge', 60.00, 'hard', 'Deliver under average time'),
('Customer Satisfaction', 75.00, 'medium', 'Maintain high customer ratings'),
('Early Bird', 35.00, 'easy', 'Complete morning shift deliveries'),
('Night Shift Premium', 45.00, 'medium', 'Work late evening/night deliveries'),
('Weekend Warrior', 80.00, 'hard', 'High volume weekend deliveries');

-- ============================================================================
-- SECTION 3: REWARD TYPES
-- ============================================================================

INSERT INTO reward_types (type_name, reward_category, description)
VALUES
('Cash Bonus', 'cash', 'Direct cash payment to wallet'),
('Tip Matching', 'bonus', 'Platform matches customer tips'),
('Earnings Boost', 'bonus', 'Percentage multiplier on earnings'),
('Streak Badge', 'badge', 'Achievement recognition badge'),
('Tier Status', 'badge', 'Tier achievement recognition'),
('Gas Credit', 'voucher', 'Fuel/gas discount or credit'),
('Platform Voucher', 'voucher', 'Credit for platform services'),
('Special Bonus', 'special', 'One-time promotional bonus');

-- ============================================================================
-- SECTION 4: SAMPLE RIDERS (Global Representation)
-- ============================================================================

-- Middle East Riders (Talabat primary market)
INSERT INTO riders (rider_code, first_name, last_name, email, phone_number, current_tier_id, status, join_date, total_earnings, total_quests_completed, average_rating)
VALUES
('RID_ME001', 'Ahmed', 'Al-Mansouri', 'ahmed.mansouri@email.ae', '+971501234567', 5, 'active', '2023-06-15', 5240.75, 487, 4.82),
('RID_ME002', 'Fatima', 'Al-Harbi', 'fatima.harbi@email.sa', '+966501234567', 4, 'active', '2023-08-20', 3850.50, 245, 4.65),
('RID_ME003', 'Mohammed', 'Al-Shehri', 'mohammed.shehri@email.sa', '+966551234567', 3, 'active', '2023-10-05', 1640.25, 98, 4.22),
('RID_ME004', 'Layla', 'Al-Dosari', 'layla.dosari@email.kw', '+96550123456', 4, 'active', '2023-07-12', 2950.00, 156, 4.58),
('RID_ME005', 'Khalid', 'Al-Otaibi', 'khalid.otaibi@email.ae', '+971501234568', 2, 'active', '2024-01-10', 580.75, 32, 3.85),

-- Southeast Asia Riders (Grab market)
('RID_SEA001', 'Budi', 'Santoso', 'budi.santoso@email.id', '+6281234567890', 4, 'active', '2023-05-18', 4120.50, 310, 4.71),
('RID_SEA002', 'Nurul', 'Rahman', 'nurul.rahman@email.my', '+60123456789', 3, 'active', '2023-09-22', 1880.25, 115, 4.35),
('RID_SEA003', 'Somchai', 'Phuket', 'somchai.p@email.th', '+668123456789', 2, 'active', '2024-02-14', 720.00, 42, 3.92),
('RID_SEA004', 'Maria', 'Santos', 'maria.santos@email.ph', '+639123456789', 5, 'active', '2023-04-08', 5680.75, 512, 4.88),

-- Europe Riders (Wolt/Deliveroo market)
('RID_EU001', 'Klaus', 'Mueller', 'klaus.mueller@email.de', '+491234567890', 4, 'active', '2023-07-30', 3520.50, 198, 4.62),
('RID_EU002', 'Elena', 'Rossi', 'elena.rossi@email.it', '+393123456789', 3, 'active', '2023-11-15', 1450.75, 87, 4.18),
('RID_EU003', 'Sophie', 'Dupont', 'sophie.dupont@email.fr', '+33612345678', 4, 'active', '2023-08-25', 2980.00, 176, 4.59),
('RID_EU004', 'Carlos', 'Garcia', 'carlos.garcia@email.es', '+34612345678', 2, 'active', '2024-01-05', 640.25, 38, 3.88),

-- North America Riders (Uber/DoorDash market)
('RID_NA001', 'Michael', 'Johnson', 'michael.j@email.us', '+14155551234', 5, 'active', '2023-03-12', 6840.50, 634, 4.85),
('RID_NA002', 'Jennifer', 'Smith', 'jennifer.smith@email.us', '+14155551235', 4, 'active', '2023-06-08', 3250.75, 201, 4.61),
('RID_NA003', 'David', 'Brown', 'david.brown@email.us', '+14155551236', 3, 'active', '2023-09-20', 1760.00, 102, 4.25),
('RID_NA004', 'Sarah', 'Wilson', 'sarah.wilson@email.ca', '+14165551234', 4, 'active', '2023-07-14', 2840.50, 167, 4.58),

-- India Riders (Multiple platforms)
('RID_IN001', 'Rajesh', 'Kumar', 'rajesh.kumar@email.in', '+919876543210', 5, 'active', '2023-05-22', 4950.25, 398, 4.79),
('RID_IN002', 'Priya', 'Singh', 'priya.singh@email.in', '+919876543211', 3, 'active', '2023-10-18', 1520.75, 93, 4.31),
('RID_IN003', 'Vikram', 'Patel', 'vikram.patel@email.in', '+919876543212', 4, 'active', '2023-08-30', 3180.50, 189, 4.55),
('RID_IN004', 'Anjali', 'Sharma', 'anjali.sharma@email.in', '+919876543213', 2, 'active', '2024-02-05', 480.00, 28, 3.75);

-- ============================================================================
-- SECTION 5: ACTIVE QUESTS (Real-world inspired)
-- ============================================================================

-- UBER EATS QUESTS
INSERT INTO quests (quest_code, quest_name, quest_type_id, description, base_reward_amount, bonus_reward, difficulty_level, min_tier_requirement_id, max_participants, start_date, end_date, status, completion_criteria, required_activities)
VALUES
('QST_UE_001', 'Uber Rush Hour - 20 Deliveries',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Uber Quest'),
  'Complete 20 deliveries during lunch hours (11am-2pm) to earn $45 bonus',
  45.00, 15.00, 'medium', 1, 5000,
  DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 8 DAY),
  'active', 'Complete 20 deliveries 11am-2pm', 20),

('QST_UE_002', 'Uber Evening Blitz - 30 Orders',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Uber Quest'),
  'Complete 30 deliveries during dinner rush (5pm-10pm) for $60 bonus',
  60.00, 20.00, 'hard', 2, 3000,
  DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 8 DAY),
  'active', 'Complete 30 deliveries 5pm-10pm', 30),

('QST_UE_003', 'Uber Boost Week',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Uber Boost'),
  'Earn 1.5x multiplier on all deliveries in Downtown area',
  30.00, 10.00, 'easy', 1, 10000,
  DATE_ADD(NOW(), INTERVAL 2 DAY), DATE_ADD(NOW(), INTERVAL 9 DAY),
  'active', '1.5x multiplier applied automatically', 999),

('QST_UE_004', 'Uber Consecutive Streak - 15 Accepts',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Uber Consecutive'),
  'Accept 15 consecutive delivery offers without declining. $25 bonus',
  25.00, 0.00, 'hard', 2, 2000,
  DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 15 DAY),
  'active', 'Accept 15 orders in a row', 15),

-- DOORDASH DASHER QUESTS
('QST_DD_001', 'DoorDash Peak Hours Challenge',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'DoorDash Peak Bonus'),
  'Complete 25 deliveries during peak hours (lunch or dinner) for $50 bonus',
  50.00, 15.00, 'medium', 1, 4000,
  DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 7 DAY),
  'active', 'Complete 25 deliveries during peak hours', 25),

('QST_DD_002', 'DoorDash Platinum Quest',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'DoorDash Platinum Bonus'),
  'Platinum Dasher exclusive: Complete 40 orders and maintain 4.8+ rating for $100',
  100.00, 30.00, 'expert', 4, 1000,
  DATE_ADD(NOW(), INTERVAL 3 DAY), DATE_ADD(NOW(), INTERVAL 10 DAY),
  'active', 'Complete 40 orders with 4.8+ rating', 40),

('QST_DD_003', 'DoorDash Quality Orders',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'DoorDash Challenge'),
  'Complete 15 orders from merchants with $15+ average order value',
  75.00, 20.00, 'hard', 2, 3000,
  DATE_ADD(NOW(), INTERVAL 2 DAY), DATE_ADD(NOW(), INTERVAL 9 DAY),
  'active', 'Complete 15 orders ($15+ average)', 15),

-- LYFT REWARDS QUESTS
('QST_LY_001', 'Lyft Zone Challenge - Downtown',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Lyft Challenge'),
  'Complete 25 rides in Downtown zone to earn $55 bonus',
  55.00, 15.00, 'medium', 1, 3500,
  DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 10 DAY),
  'active', 'Complete 25 rides in Downtown', 25),

('QST_LY_002', 'Lyft Streak Bonus - 10 Consecutive',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Lyft Streak Bonus'),
  'Accept 10 consecutive ride requests for $40 bonus',
  40.00, 0.00, 'medium', 2, 4000,
  DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 12 DAY),
  'active', 'Accept 10 requests in a row', 10),

('QST_LY_003', 'Lyft Destination Bonus - Airport Runs',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Lyft Destination Bonus'),
  'Complete 8 rides to/from Airport for $30 bonus',
  30.00, 10.00, 'easy', 1, 2000,
  DATE_ADD(NOW(), INTERVAL 5 DAY), DATE_ADD(NOW(), INTERVAL 12 DAY),
  'active', 'Complete 8 airport rides', 8),

-- GRAB SOUTHEAST ASIA QUESTS
('QST_GB_001', 'Grab Rush Hour Bonus',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Grab Rush Hour Bonus'),
  'Complete 20 deliveries during rush hours (11-2pm, 5-8pm) for 35,000 PHP/$600',
  35.00, 12.00, 'medium', 1, 5000,
  DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 7 DAY),
  'active', 'Complete 20 rush hour deliveries', 20),

('QST_GB_002', 'Grab Perfect Rating Reward',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Grab Perfect Rating'),
  'Maintain 5.0 rating on 30 consecutive deliveries for 80,000 PHP/$1,370',
  80.00, 25.00, 'hard', 3, 2000,
  DATE_ADD(NOW(), INTERVAL 2 DAY), DATE_ADD(NOW(), INTERVAL 14 DAY),
  'active', 'Complete 30 orders with perfect 5.0 rating', 30),

('QST_GB_003', 'Grab Loyalty Reward - Weekly',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Grab Loyalty Reward'),
  'Work at least 5 hours every day this week for 60,000 PHP/$1,025',
  60.00, 0.00, 'medium', 2, 8000,
  DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 8 DAY),
  'active', 'Work 5+ hours daily for 7 days', 35),

-- TALABAT QUESTS
('QST_TB_001', 'Talabat Peak Hours Blitz',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Talabat Peak Hours'),
  'Complete 25 deliveries during peak hours (11am-2pm, 6pm-9pm) for 40,000 AED/$11',
  40.00, 12.00, 'medium', 1, 6000,
  DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 7 DAY),
  'active', 'Complete 25 deliveries in peak hours', 25),

('QST_TB_002', 'Talabat Weekend Rush - 50 Orders',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Talabat Weekend Rush'),
  'Complete 50 deliveries Friday-Sunday for 75,000 AED/$20 bonus',
  75.00, 20.00, 'hard', 2, 3000,
  DATE_ADD(NOW(), INTERVAL 5 DAY), DATE_ADD(NOW(), INTERVAL 9 DAY),
  'active', 'Complete 50 orders on weekends', 50),

('QST_TB_003', 'Talabat Tip Multiplier Week',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Talabat Tip Multiplier'),
  'Talabat matches 100% of customer tips this week (max 50,000 AED/$13.60)',
  50.00, 0.00, 'easy', 1, 10000,
  DATE_ADD(NOW(), INTERVAL 3 DAY), DATE_ADD(NOW(), INTERVAL 10 DAY),
  'active', 'Tips matched 1:1 automatically', 999),

-- WOLT EUROPE QUESTS
('QST_WLT_001', 'Wolt Hot Spot Challenge',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Wolt Hot Spot'),
  'Complete 30 orders in designated hot spot areas for €45 bonus',
  45.00, 15.00, 'medium', 1, 4000,
  DATE_ADD(NOW(), INTERVAL 2 DAY), DATE_ADD(NOW(), INTERVAL 9 DAY),
  'active', 'Complete 30 orders in hot spots', 30),

('QST_WLT_002', 'Wolt Rating Bonus',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Wolt Rating Bonus'),
  'Maintain 4.85+ rating on 40 consecutive deliveries for €70 bonus',
  70.00, 20.00, 'hard', 3, 2500,
  DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 12 DAY),
  'active', 'Complete 40 orders with 4.85+ rating', 40),

('QST_WLT_003', 'Wolt Surge Surge',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Wolt Surge Surge'),
  'Complete 20 deliveries during surge pricing (2x bonus)',
  55.00, 15.00, 'hard', 2, 3500,
  DATE_ADD(NOW(), INTERVAL 4 DAY), DATE_ADD(NOW(), INTERVAL 11 DAY),
  'active', 'Complete 20 surging orders', 20),

-- DELIVEROO UK/ASIA QUESTS
('QST_DR_001', 'Deliveroo High Demand Weekend',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Deliveroo High Demand'),
  'Complete 35 deliveries Friday-Sunday for £65 bonus',
  65.00, 18.00, 'hard', 2, 4000,
  DATE_ADD(NOW(), INTERVAL 5 DAY), DATE_ADD(NOW(), INTERVAL 9 DAY),
  'active', 'Complete 35 weekend orders', 35),

('QST_DR_002', 'Deliveroo Boost Multiplier',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Deliveroo Boost'),
  'Earn 1.3x multiplier on all orders during peak hours (12-2pm, 6-9pm)',
  50.00, 0.00, 'easy', 1, 8000,
  DATE_ADD(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 8 DAY),
  'active', '1.3x multiplier applied', 999),

('QST_DR_003', 'Deliveroo Guaranteed Earnings',
  (SELECT quest_type_id FROM quest_types WHERE type_name = 'Deliveroo Guaranteed'),
  'Complete 20 orders with guaranteed minimum £4.50 per delivery',
  90.00, 0.00, 'medium', 1, 2500,
  DATE_ADD(NOW(), INTERVAL 6 DAY), DATE_ADD(NOW(), INTERVAL 13 DAY),
  'active', 'Complete 20 orders (guaranteed)', 20);

-- ============================================================================
-- SECTION 6: SAMPLE QUEST ENROLLMENTS
-- ============================================================================

INSERT INTO quest_participants (rider_id, quest_id, participation_status, enrollment_date, progress_percentage, attempts)
SELECT
  r.rider_id,
  q.quest_id,
  'in_progress',
  NOW(),
  FLOOR(RAND() * 100),
  FLOOR(RAND() * 3) + 1
FROM riders r
CROSS JOIN quests q
WHERE r.status = 'active' AND q.status = 'active'
LIMIT 200;

-- ============================================================================
-- SECTION 7: SAMPLE QUEST COMPLETIONS
-- ============================================================================

INSERT INTO quest_completions
(participant_id, rider_id, quest_id, completion_date, completion_time_hours, quality_rating, reward_earned, tier_bonus_applied)
SELECT
  qp.participant_id,
  qp.rider_id,
  qp.quest_id,
  DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 30) DAY),
  ROUND(RAND() * 20 + 5, 2),
  FLOOR(RAND() * 2) + 4,  -- 4 or 5 star rating
  q.base_reward_amount,
  (q.base_reward_amount * (it.bonus_multiplier - 1))
FROM quest_participants qp
JOIN quest_participants qp2 ON qp.participant_id = qp2.participant_id
JOIN quests q ON qp.quest_id = q.quest_id
JOIN riders r ON qp.rider_id = r.rider_id
JOIN incentive_tiers it ON r.current_tier_id = it.tier_id
WHERE qp.participation_status IN ('completed', 'in_progress')
LIMIT 150;

-- ============================================================================
-- SECTION 8: SAMPLE REWARD PAYOUTS
-- ============================================================================

INSERT INTO reward_payouts
(rider_id, quest_id, completion_id, reward_type_id, reward_amount, payout_status, payout_date, payment_method, transaction_id)
SELECT
  qc.rider_id,
  qc.quest_id,
  qc.completion_id,
  (SELECT reward_type_id FROM reward_types WHERE type_name = 'Cash Bonus' LIMIT 1),
  qc.reward_earned + qc.tier_bonus_applied,
  'processed',
  qc.completion_date,
  'wallet',
  CONCAT('TXN_', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'), '_', FLOOR(RAND() * 10000))
FROM quest_completions qc
WHERE qc.completion_date < DATE_SUB(NOW(), INTERVAL 1 DAY);

-- ============================================================================
-- SECTION 9: UPDATE RIDER STATS
-- ============================================================================

-- Insert or update rider stats
INSERT INTO rider_stats
(rider_id, total_quests_enrolled, total_quests_completed, total_quests_abandoned,
 completion_rate, average_completion_time_hours, average_quality_rating,
 total_earnings, earnings_this_month, earnings_this_week)
SELECT
  r.rider_id,
  COUNT(DISTINCT CASE WHEN qp.participation_status IN ('completed', 'in_progress', 'enrolled') THEN qp.quest_id END),
  COUNT(DISTINCT CASE WHEN qp.participation_status = 'completed' THEN qp.quest_id END),
  COUNT(DISTINCT CASE WHEN qp.participation_status = 'abandoned' THEN qp.quest_id END),
  ROUND(100.0 * COUNT(DISTINCT CASE WHEN qp.participation_status = 'completed' THEN qp.quest_id END)
        / NULLIF(COUNT(DISTINCT qp.quest_id), 0), 2),
  ROUND(AVG(qc.completion_time_hours), 2),
  ROUND(AVG(qc.quality_rating), 2),
  COALESCE(SUM(qc.reward_earned + qc.tier_bonus_applied), 0),
  COALESCE(SUM(CASE WHEN MONTH(qc.completion_date) = MONTH(NOW())
    AND YEAR(qc.completion_date) = YEAR(NOW()) THEN qc.reward_earned + qc.tier_bonus_applied ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN WEEK(qc.completion_date) = WEEK(NOW())
    AND YEAR(qc.completion_date) = YEAR(NOW()) THEN qc.reward_earned + qc.tier_bonus_applied ELSE 0 END), 0)
FROM riders r
LEFT JOIN quest_participants qp ON r.rider_id = qp.rider_id
LEFT JOIN quest_completions qc ON qp.participant_id = qc.participant_id
WHERE r.status = 'active'
GROUP BY r.rider_id
ON DUPLICATE KEY UPDATE
  total_quests_enrolled = VALUES(total_quests_enrolled),
  total_quests_completed = VALUES(total_quests_completed),
  completion_rate = VALUES(completion_rate),
  average_quality_rating = VALUES(average_quality_rating),
  total_earnings = VALUES(total_earnings),
  earnings_this_month = VALUES(earnings_this_month),
  earnings_this_week = VALUES(earnings_this_week);

-- ============================================================================
-- SECTION 10: ANALYTICS & VERIFICATION QUERIES
-- ============================================================================

-- Verify data insertion
SELECT 'SUMMARY STATISTICS' as section;
SELECT COUNT(*) as total_riders FROM riders WHERE status = 'active';
SELECT COUNT(*) as total_active_quests FROM quests WHERE status = 'active';
SELECT COUNT(*) as total_participants FROM quest_participants;
SELECT COUNT(*) as total_completions FROM quest_completions;
SELECT SUM(reward_earned + tier_bonus_applied) as total_rewards_distributed FROM quest_completions;

-- Show top performers by region
SELECT 'TOP PERFORMERS BY REGION' as section;
SELECT
  CASE
    WHEN rider_code LIKE 'RID_ME%' THEN 'Middle East'
    WHEN rider_code LIKE 'RID_SEA%' THEN 'Southeast Asia'
    WHEN rider_code LIKE 'RID_EU%' THEN 'Europe'
    WHEN rider_code LIKE 'RID_NA%' THEN 'North America'
    WHEN rider_code LIKE 'RID_IN%' THEN 'India'
  END as region,
  AVG(total_earnings) as avg_earnings,
  AVG(average_rating) as avg_rating,
  COUNT(*) as rider_count
FROM riders
WHERE status = 'active'
GROUP BY region
ORDER BY avg_earnings DESC;

-- Show quest participation summary
SELECT 'QUEST PARTICIPATION' as section;
SELECT
  q.quest_name,
  COUNT(DISTINCT qp.rider_id) as participants,
  SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END) as completed,
  ROUND(100.0 * SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT qp.rider_id), 0), 2) as completion_rate
FROM quests q
LEFT JOIN quest_participants qp ON q.quest_id = qp.quest_id
WHERE q.status = 'active'
GROUP BY q.quest_id, q.quest_name
ORDER BY completion_rate DESC;

-- Show tier distribution
SELECT 'TIER DISTRIBUTION' as section;
SELECT
  it.tier_name,
  COUNT(r.rider_id) as rider_count,
  AVG(r.total_earnings) as avg_earnings,
  AVG(r.average_rating) as avg_rating
FROM incentive_tiers it
LEFT JOIN riders r ON it.tier_id = r.current_tier_id AND r.status = 'active'
GROUP BY it.tier_id, it.tier_name
ORDER BY it.tier_level ASC;

-- ============================================================================
-- SECTION 11: INDEX OPTIMIZATION
-- ============================================================================

-- Create additional indexes for common queries
CREATE INDEX idx_completion_by_month ON quest_completions(YEAR(completion_date), MONTH(completion_date));
CREATE INDEX idx_active_participants ON quest_participants(quest_id, participation_status) WHERE participation_status IN ('enrolled', 'in_progress');
CREATE INDEX idx_region_earnings ON riders(SUBSTRING(rider_code, 1, 6), total_earnings);

-- ============================================================================
-- SECTION 12: DATA VALIDATION
-- ============================================================================

-- Check data integrity
SELECT 'DATA VALIDATION CHECKS' as check_name;

-- Check for orphaned records
SELECT 'Check: Orphaned quest participants' as check_type, COUNT(*) as issue_count
FROM quest_participants qp
WHERE NOT EXISTS (SELECT 1 FROM riders WHERE rider_id = qp.rider_id)
   OR NOT EXISTS (SELECT 1 FROM quests WHERE quest_id = qp.quest_id);

-- Check tier multipliers are reasonable
SELECT 'Check: Tier multiplier validation' as check_type,
       SUM(CASE WHEN bonus_multiplier < 1.0 OR bonus_multiplier > 3.0 THEN 1 ELSE 0 END) as issues
FROM incentive_tiers;

-- Check for negative earnings
SELECT 'Check: Negative earnings' as check_type, COUNT(*) as issue_count
FROM riders
WHERE total_earnings < 0;

-- ============================================================================
-- END OF POPULATION SCRIPT
-- Execution time: ~5-10 seconds depending on database size
-- Total records: ~1,400+ entries across all tables
-- ============================================================================
