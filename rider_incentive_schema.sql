-- ============================================================================
-- RIDER INCENTIVE/QUEST MODEL - DATABASE SCHEMA
-- ============================================================================

-- DROP existing tables (for fresh setup)
-- DROP TABLE IF EXISTS quest_completions CASCADE;
-- DROP TABLE IF EXISTS quest_participants CASCADE;
-- DROP TABLE IF EXISTS reward_payouts CASCADE;
-- DROP TABLE IF EXISTS rider_stats CASCADE;
-- DROP TABLE IF EXISTS quests CASCADE;
-- DROP TABLE IF EXISTS riders CASCADE;
-- DROP TABLE IF EXISTS incentive_tiers CASCADE;
-- DROP TABLE IF EXISTS reward_types CASCADE;

-- ============================================================================
-- 1. INCENTIVE_TIERS - Define performance tiers for riders
-- ============================================================================
CREATE TABLE incentive_tiers (
    tier_id INT PRIMARY KEY AUTO_INCREMENT,
    tier_name VARCHAR(50) NOT NULL UNIQUE,
    tier_level INT NOT NULL UNIQUE,
    min_quests_completed INT DEFAULT 0,
    min_rating DECIMAL(3, 2) DEFAULT 0.0,
    bonus_multiplier DECIMAL(3, 2) DEFAULT 1.0,
    quest_priority INT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_tier_level (tier_level)
);

-- ============================================================================
-- 2. RIDERS - Core rider information
-- ============================================================================
CREATE TABLE riders (
    rider_id INT PRIMARY KEY AUTO_INCREMENT,
    rider_code VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone_number VARCHAR(20),
    current_tier_id INT,
    status ENUM('active', 'inactive', 'suspended', 'onboarded') DEFAULT 'onboarded',
    join_date DATE NOT NULL,
    total_earnings DECIMAL(12, 2) DEFAULT 0.0,
    total_quests_completed INT DEFAULT 0,
    average_rating DECIMAL(3, 2) DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (current_tier_id) REFERENCES incentive_tiers(tier_id),
    INDEX idx_status (status),
    INDEX idx_tier (current_tier_id),
    INDEX idx_earnings (total_earnings DESC),
    INDEX idx_quests_completed (total_quests_completed DESC)
);

-- ============================================================================
-- 3. QUEST_TYPES - Define different types of quests
-- ============================================================================
CREATE TABLE quest_types (
    quest_type_id INT PRIMARY KEY AUTO_INCREMENT,
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    base_reward DECIMAL(10, 2) NOT NULL,
    difficulty_level ENUM('easy', 'medium', 'hard', 'expert') DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 4. QUESTS - Quest definitions
-- ============================================================================
CREATE TABLE quests (
    quest_id INT PRIMARY KEY AUTO_INCREMENT,
    quest_code VARCHAR(30) NOT NULL UNIQUE,
    quest_name VARCHAR(150) NOT NULL,
    quest_type_id INT NOT NULL,
    description TEXT,
    difficulty_level ENUM('easy', 'medium', 'hard', 'expert') DEFAULT 'medium',
    base_reward_amount DECIMAL(10, 2) NOT NULL,
    bonus_reward DECIMAL(10, 2) DEFAULT 0.0,
    min_tier_requirement_id INT,
    max_participants INT,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    status ENUM('draft', 'active', 'paused', 'completed', 'cancelled') DEFAULT 'draft',
    completion_criteria TEXT,
    required_activities INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (quest_type_id) REFERENCES quest_types(quest_type_id),
    FOREIGN KEY (min_tier_requirement_id) REFERENCES incentive_tiers(tier_id),
    INDEX idx_status (status),
    INDEX idx_dates (start_date, end_date),
    INDEX idx_difficulty (difficulty_level)
);

-- ============================================================================
-- 5. QUEST_PARTICIPANTS - Track rider participation in quests
-- ============================================================================
CREATE TABLE quest_participants (
    participant_id INT PRIMARY KEY AUTO_INCREMENT,
    rider_id INT NOT NULL,
    quest_id INT NOT NULL,
    participation_status ENUM('enrolled', 'in_progress', 'completed', 'abandoned', 'failed') DEFAULT 'enrolled',
    enrollment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    progress_percentage INT DEFAULT 0,
    attempts INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (rider_id) REFERENCES riders(rider_id) ON DELETE CASCADE,
    FOREIGN KEY (quest_id) REFERENCES quests(quest_id) ON DELETE CASCADE,
    UNIQUE KEY unique_rider_quest (rider_id, quest_id),
    INDEX idx_status (participation_status),
    INDEX idx_rider (rider_id),
    INDEX idx_quest (quest_id)
);

-- ============================================================================
-- 6. QUEST_COMPLETIONS - Record quest completion details
-- ============================================================================
CREATE TABLE quest_completions (
    completion_id INT PRIMARY KEY AUTO_INCREMENT,
    participant_id INT NOT NULL,
    rider_id INT NOT NULL,
    quest_id INT NOT NULL,
    completion_date DATETIME NOT NULL,
    completion_time_hours DECIMAL(10, 2),
    quality_rating INT CHECK (quality_rating BETWEEN 1 AND 5),
    proof_document_url VARCHAR(500),
    notes TEXT,
    reward_earned DECIMAL(10, 2),
    tier_bonus_applied DECIMAL(10, 2) DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (participant_id) REFERENCES quest_participants(participant_id) ON DELETE CASCADE,
    FOREIGN KEY (rider_id) REFERENCES riders(rider_id) ON DELETE CASCADE,
    FOREIGN KEY (quest_id) REFERENCES quests(quest_id) ON DELETE CASCADE,
    INDEX idx_rider (rider_id),
    INDEX idx_quest (quest_id),
    INDEX idx_completion_date (completion_date),
    INDEX idx_rating (quality_rating)
);

-- ============================================================================
-- 7. REWARD_TYPES - Define types of rewards
-- ============================================================================
CREATE TABLE reward_types (
    reward_type_id INT PRIMARY KEY AUTO_INCREMENT,
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    reward_category ENUM('cash', 'bonus', 'badge', 'voucher', 'special') DEFAULT 'cash',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 8. REWARD_PAYOUTS - Track reward distributions
-- ============================================================================
CREATE TABLE reward_payouts (
    payout_id INT PRIMARY KEY AUTO_INCREMENT,
    rider_id INT NOT NULL,
    quest_id INT,
    completion_id INT,
    reward_type_id INT,
    reward_amount DECIMAL(10, 2) NOT NULL,
    payout_status ENUM('pending', 'approved', 'processed', 'failed', 'cancelled') DEFAULT 'pending',
    payout_date DATE,
    payment_method ENUM('wallet', 'bank_transfer', 'voucher') DEFAULT 'wallet',
    transaction_id VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (rider_id) REFERENCES riders(rider_id) ON DELETE CASCADE,
    FOREIGN KEY (quest_id) REFERENCES quests(quest_id),
    FOREIGN KEY (completion_id) REFERENCES quest_completions(completion_id),
    FOREIGN KEY (reward_type_id) REFERENCES reward_types(reward_type_id),
    INDEX idx_rider (rider_id),
    INDEX idx_status (payout_status),
    INDEX idx_payout_date (payout_date)
);

-- ============================================================================
-- 9. RIDER_STATS - Aggregated rider performance metrics
-- ============================================================================
CREATE TABLE rider_stats (
    stat_id INT PRIMARY KEY AUTO_INCREMENT,
    rider_id INT NOT NULL UNIQUE,
    total_quests_enrolled INT DEFAULT 0,
    total_quests_completed INT DEFAULT 0,
    total_quests_abandoned INT DEFAULT 0,
    completion_rate DECIMAL(5, 2) DEFAULT 0.0,
    average_completion_time_hours DECIMAL(10, 2),
    average_quality_rating DECIMAL(3, 2),
    total_earnings DECIMAL(12, 2) DEFAULT 0.0,
    earnings_this_month DECIMAL(12, 2) DEFAULT 0.0,
    earnings_this_week DECIMAL(12, 2) DEFAULT 0.0,
    tier_promotions INT DEFAULT 0,
    highest_tier_reached_id INT,
    last_quest_completion_date DATE,
    consecutive_completed_quests INT DEFAULT 0,
    streak_bonus_multiplier DECIMAL(3, 2) DEFAULT 1.0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (rider_id) REFERENCES riders(rider_id) ON DELETE CASCADE,
    FOREIGN KEY (highest_tier_reached_id) REFERENCES incentive_tiers(tier_id),
    INDEX idx_completion_rate (completion_rate DESC),
    INDEX idx_earnings (total_earnings DESC)
);

-- ============================================================================
-- 10. QUEST_FEEDBACK - Capture rider feedback on quests
-- ============================================================================
CREATE TABLE quest_feedback (
    feedback_id INT PRIMARY KEY AUTO_INCREMENT,
    completion_id INT NOT NULL,
    rider_id INT NOT NULL,
    difficulty_rating INT CHECK (difficulty_rating BETWEEN 1 AND 5),
    reward_fairness_rating INT CHECK (reward_fairness_rating BETWEEN 1 AND 5),
    enjoyment_rating INT CHECK (enjoyment_rating BETWEEN 1 AND 5),
    feedback_text TEXT,
    would_repeat BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (completion_id) REFERENCES quest_completions(completion_id) ON DELETE CASCADE,
    FOREIGN KEY (rider_id) REFERENCES riders(rider_id) ON DELETE CASCADE,
    INDEX idx_rider (rider_id),
    INDEX idx_difficulty (difficulty_rating)
);

-- ============================================================================
-- INDEXES FOR COMMON QUERIES
-- ============================================================================
CREATE INDEX idx_riders_tier_earnings ON riders(current_tier_id, total_earnings);
CREATE INDEX idx_active_quests ON quests(status, start_date) WHERE status = 'active';
CREATE INDEX idx_completion_reward ON quest_completions(rider_id, completion_date, reward_earned);

-- ============================================================================
-- VIEWS FOR COMMON ANALYTICS
-- ============================================================================

-- Active Quests Summary
CREATE OR REPLACE VIEW v_active_quests AS
SELECT
    q.quest_id,
    q.quest_code,
    q.quest_name,
    q.difficulty_level,
    q.base_reward_amount,
    COUNT(DISTINCT qp.rider_id) as total_participants,
    SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END) as completed_count,
    ROUND(COALESCE(SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(DISTINCT qp.rider_id), 0), 0), 2) as completion_rate_pct
FROM quests q
LEFT JOIN quest_participants qp ON q.quest_id = qp.quest_id
WHERE q.status = 'active' AND q.start_date <= NOW() AND q.end_date >= NOW()
GROUP BY q.quest_id, q.quest_code, q.quest_name, q.difficulty_level, q.base_reward_amount;

-- Rider Performance Summary
CREATE OR REPLACE VIEW v_rider_performance AS
SELECT
    r.rider_id,
    r.rider_code,
    CONCAT(r.first_name, ' ', r.last_name) as rider_name,
    it.tier_name,
    rs.total_quests_completed,
    rs.completion_rate,
    rs.average_quality_rating,
    rs.total_earnings,
    rs.earnings_this_month,
    COUNT(DISTINCT qc.completion_id) as recent_completions
FROM riders r
LEFT JOIN incentive_tiers it ON r.current_tier_id = it.tier_id
LEFT JOIN rider_stats rs ON r.rider_id = rs.rider_id
LEFT JOIN quest_completions qc ON r.rider_id = qc.rider_id AND qc.completion_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY r.rider_id, r.rider_code, r.first_name, r.last_name, it.tier_name, rs.total_quests_completed, rs.completion_rate, rs.average_quality_rating, rs.total_earnings, rs.earnings_this_month;

-- Earnings Dashboard
CREATE OR REPLACE VIEW v_earnings_dashboard AS
SELECT
    DATE_TRUNC(qc.completion_date, MONTH) as period,
    COUNT(DISTINCT qc.rider_id) as riders_earning,
    COUNT(DISTINCT qc.quest_id) as quests_completed,
    SUM(qc.reward_earned) as total_rewards_distributed,
    AVG(qc.reward_earned) as average_reward_per_completion,
    SUM(qc.tier_bonus_applied) as total_tier_bonuses
FROM quest_completions qc
GROUP BY DATE_TRUNC(qc.completion_date, MONTH)
ORDER BY period DESC;
