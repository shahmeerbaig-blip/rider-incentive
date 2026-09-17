"""
Rider Incentive/Quest Model - Python Implementation Guide

This module provides helper classes and functions for interacting with the
Rider Incentive/Quest database model.

Dependencies:
    - mysql-connector-python
    - pandas
"""

import mysql.connector
from mysql.connector import Error
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from decimal import Decimal
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# ============================================================================
# DATA CLASSES
# ============================================================================

@dataclass
class Rider:
    """Represents a rider in the system"""
    rider_id: int
    rider_code: str
    first_name: str
    last_name: str
    email: str
    current_tier_id: int
    status: str
    total_earnings: Decimal
    total_quests_completed: int
    average_rating: Decimal

    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"


@dataclass
class Quest:
    """Represents a quest in the system"""
    quest_id: int
    quest_code: str
    quest_name: str
    base_reward_amount: Decimal
    difficulty_level: str
    status: str
    start_date: datetime
    end_date: datetime


@dataclass
class Tier:
    """Represents an incentive tier"""
    tier_id: int
    tier_name: str
    tier_level: int
    bonus_multiplier: Decimal
    min_quests_completed: int
    min_rating: Decimal


# ============================================================================
# DATABASE CONNECTION
# ============================================================================

class DatabaseConnection:
    """Manages MySQL database connections"""

    def __init__(self, host: str, user: str, password: str, database: str):
        """
        Initialize database connection parameters

        Args:
            host: Database host (e.g., 'localhost')
            user: Database user
            password: Database password
            database: Database name
        """
        self.config = {
            'host': host,
            'user': user,
            'password': password,
            'database': database
        }
        self.connection = None

    def connect(self):
        """Establish database connection"""
        try:
            self.connection = mysql.connector.connect(**self.config)
            logger.info("Database connection established")
        except Error as e:
            logger.error(f"Connection error: {e}")
            raise

    def disconnect(self):
        """Close database connection"""
        if self.connection:
            self.connection.close()
            logger.info("Database connection closed")

    def execute_query(self, query: str, params: Tuple = None, fetch: bool = False):
        """
        Execute a SQL query

        Args:
            query: SQL query string
            params: Query parameters
            fetch: Whether to fetch results

        Returns:
            Query results if fetch=True, otherwise None
        """
        cursor = self.connection.cursor(dictionary=True)
        try:
            cursor.execute(query, params or ())
            if fetch:
                return cursor.fetchall()
            self.connection.commit()
            return cursor.rowcount
        except Error as e:
            logger.error(f"Query error: {e}")
            self.connection.rollback()
            raise
        finally:
            cursor.close()


# ============================================================================
# RIDER MANAGEMENT
# ============================================================================

class RiderManager:
    """Manages rider-related operations"""

    def __init__(self, db: DatabaseConnection):
        self.db = db

    def get_rider_by_code(self, rider_code: str) -> Optional[Rider]:
        """Fetch rider by rider code"""
        query = """
        SELECT rider_id, rider_code, first_name, last_name, email,
               current_tier_id, status, total_earnings,
               total_quests_completed, average_rating
        FROM riders
        WHERE rider_code = %s
        """
        result = self.db.execute_query(query, (rider_code,), fetch=True)
        if result:
            row = result[0]
            return Rider(
                rider_id=row['rider_id'],
                rider_code=row['rider_code'],
                first_name=row['first_name'],
                last_name=row['last_name'],
                email=row['email'],
                current_tier_id=row['current_tier_id'],
                status=row['status'],
                total_earnings=row['total_earnings'],
                total_quests_completed=row['total_quests_completed'],
                average_rating=row['average_rating']
            )
        return None

    def get_top_riders(self, limit: int = 20) -> List[Dict]:
        """Get top riders by earnings"""
        query = """
        SELECT
            r.rider_code,
            CONCAT(r.first_name, ' ', r.last_name) as rider_name,
            it.tier_name,
            r.total_quests_completed,
            r.average_rating,
            r.total_earnings,
            RANK() OVER (ORDER BY r.total_earnings DESC) as rank
        FROM riders r
        JOIN incentive_tiers it ON r.current_tier_id = it.tier_id
        WHERE r.status = 'active'
        ORDER BY r.total_earnings DESC
        LIMIT %s
        """
        return self.db.execute_query(query, (limit,), fetch=True)

    def get_rider_stats(self, rider_id: int) -> Optional[Dict]:
        """Get detailed stats for a rider"""
        query = """
        SELECT
            r.rider_code,
            CONCAT(r.first_name, ' ', r.last_name) as rider_name,
            it.tier_name,
            rs.total_quests_enrolled,
            rs.total_quests_completed,
            rs.completion_rate,
            rs.average_quality_rating,
            rs.total_earnings,
            rs.earnings_this_month,
            rs.consecutive_completed_quests,
            MAX(qc.completion_date) as last_activity
        FROM riders r
        JOIN incentive_tiers it ON r.current_tier_id = it.tier_id
        JOIN rider_stats rs ON r.rider_id = rs.rider_id
        LEFT JOIN quest_completions qc ON r.rider_id = qc.rider_id
        WHERE r.rider_id = %s
        GROUP BY r.rider_id
        """
        results = self.db.execute_query(query, (rider_id,), fetch=True)
        return results[0] if results else None


# ============================================================================
# QUEST MANAGEMENT
# ============================================================================

class QuestManager:
    """Manages quest-related operations"""

    def __init__(self, db: DatabaseConnection):
        self.db = db

    def get_active_quests(self) -> List[Dict]:
        """Get all currently active quests"""
        query = """
        SELECT
            quest_id,
            quest_code,
            quest_name,
            difficulty_level,
            base_reward_amount,
            start_date,
            end_date,
            status
        FROM quests
        WHERE status = 'active'
            AND start_date <= NOW()
            AND end_date >= NOW()
        ORDER BY start_date DESC
        """
        return self.db.execute_query(query, fetch=True)

    def get_quest_participation_stats(self, quest_id: int) -> Optional[Dict]:
        """Get participation statistics for a quest"""
        query = """
        SELECT
            q.quest_code,
            q.quest_name,
            COUNT(DISTINCT qp.rider_id) as total_participants,
            SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END) as completed,
            SUM(CASE WHEN qp.participation_status = 'in_progress' THEN 1 ELSE 0 END) as in_progress,
            SUM(CASE WHEN qp.participation_status = 'abandoned' THEN 1 ELSE 0 END) as abandoned,
            ROUND(100.0 * SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END)
                  / NULLIF(COUNT(DISTINCT qp.rider_id), 0), 2) as completion_rate_pct,
            AVG(qc.quality_rating) as avg_quality_rating
        FROM quests q
        LEFT JOIN quest_participants qp ON q.quest_id = qp.quest_id
        LEFT JOIN quest_completions qc ON qp.participant_id = qc.participant_id
        WHERE q.quest_id = %s
        GROUP BY q.quest_id, q.quest_code, q.quest_name
        """
        results = self.db.execute_query(query, (quest_id,), fetch=True)
        return results[0] if results else None

    def enroll_rider(self, rider_id: int, quest_id: int) -> bool:
        """Enroll a rider in a quest"""
        try:
            # Check if already enrolled
            check_query = """
            SELECT COUNT(*) as count FROM quest_participants
            WHERE rider_id = %s AND quest_id = %s
            """
            result = self.db.execute_query(check_query, (rider_id, quest_id), fetch=True)
            if result[0]['count'] > 0:
                logger.warning(f"Rider {rider_id} already enrolled in quest {quest_id}")
                return False

            # Enroll rider
            insert_query = """
            INSERT INTO quest_participants
            (rider_id, quest_id, participation_status, enrollment_date)
            VALUES (%s, %s, 'enrolled', NOW())
            """
            self.db.execute_query(insert_query, (rider_id, quest_id))
            logger.info(f"Rider {rider_id} enrolled in quest {quest_id}")
            return True
        except Error as e:
            logger.error(f"Enrollment error: {e}")
            return False


# ============================================================================
# REWARD MANAGEMENT
# ============================================================================

class RewardManager:
    """Manages reward and earnings operations"""

    def __init__(self, db: DatabaseConnection):
        self.db = db

    def get_tier_by_id(self, tier_id: int) -> Optional[Tier]:
        """Fetch tier information"""
        query = """
        SELECT tier_id, tier_name, tier_level, bonus_multiplier,
               min_quests_completed, min_rating
        FROM incentive_tiers
        WHERE tier_id = %s
        """
        result = self.db.execute_query(query, (tier_id,), fetch=True)
        if result:
            row = result[0]
            return Tier(
                tier_id=row['tier_id'],
                tier_name=row['tier_name'],
                tier_level=row['tier_level'],
                bonus_multiplier=row['bonus_multiplier'],
                min_quests_completed=row['min_quests_completed'],
                min_rating=row['min_rating']
            )
        return None

    def calculate_reward(self, base_reward: Decimal, tier_multiplier: Decimal,
                        bonus_multiplier: Decimal = Decimal('1.0')) -> Decimal:
        """
        Calculate total reward amount

        Formula: (base_reward * tier_multiplier) * bonus_multiplier
        """
        return base_reward * tier_multiplier * bonus_multiplier

    def get_monthly_earnings(self, year: int, month: int) -> Dict:
        """Get earnings summary for a specific month"""
        query = """
        SELECT
            COUNT(DISTINCT qc.rider_id) as active_riders,
            COUNT(DISTINCT qc.completion_id) as total_completions,
            SUM(qc.reward_earned) as base_rewards,
            SUM(qc.tier_bonus_applied) as tier_bonuses,
            SUM(qc.reward_earned + qc.tier_bonus_applied) as total_rewards,
            AVG(qc.reward_earned) as avg_reward_per_completion,
            AVG(qc.quality_rating) as avg_quality_rating
        FROM quest_completions qc
        WHERE YEAR(qc.completion_date) = %s
            AND MONTH(qc.completion_date) = %s
        """
        result = self.db.execute_query(query, (year, month), fetch=True)
        return result[0] if result else {}

    def process_payout(self, payout_id: int) -> bool:
        """Process a pending payout"""
        try:
            update_query = """
            UPDATE reward_payouts
            SET payout_status = 'approved',
                payout_date = NOW()
            WHERE payout_id = %s
                AND payout_status = 'pending'
            """
            self.db.execute_query(update_query, (payout_id,))
            logger.info(f"Payout {payout_id} processed")
            return True
        except Error as e:
            logger.error(f"Payout error: {e}")
            return False


# ============================================================================
# ANALYTICS
# ============================================================================

class Analytics:
    """Provides analytics and reporting functions"""

    def __init__(self, db: DatabaseConnection):
        self.db = db

    def get_completion_rate_by_difficulty(self) -> List[Dict]:
        """Analyze completion rates by quest difficulty"""
        query = """
        SELECT
            q.difficulty_level,
            COUNT(DISTINCT qp.rider_id) as total_participants,
            SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END) as completed,
            ROUND(100.0 * SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END)
                  / NULLIF(COUNT(DISTINCT qp.rider_id), 0), 2) as completion_rate
        FROM quests q
        LEFT JOIN quest_participants qp ON q.quest_id = qp.quest_id
        WHERE q.status = 'active'
        GROUP BY q.difficulty_level
        ORDER BY completion_rate DESC
        """
        return self.db.execute_query(query, fetch=True)

    def get_at_risk_riders(self, days_inactive: int = 30) -> List[Dict]:
        """Identify riders inactive for specified days"""
        query = """
        SELECT
            r.rider_code,
            CONCAT(r.first_name, ' ', r.last_name) as rider_name,
            it.tier_name,
            rs.total_quests_completed,
            MAX(qc.completion_date) as last_activity,
            DATEDIFF(NOW(), MAX(qc.completion_date)) as days_inactive,
            rs.total_earnings
        FROM riders r
        JOIN incentive_tiers it ON r.current_tier_id = it.tier_id
        JOIN rider_stats rs ON r.rider_id = rs.rider_id
        LEFT JOIN quest_completions qc ON r.rider_id = qc.rider_id
        WHERE r.status = 'active'
        GROUP BY r.rider_id
        HAVING DATEDIFF(NOW(), MAX(qc.completion_date)) > %s
        ORDER BY days_inactive DESC
        """
        return self.db.execute_query(query, (days_inactive,), fetch=True)

    def get_tier_distribution(self) -> List[Dict]:
        """Get distribution of riders across tiers"""
        query = """
        SELECT
            it.tier_name,
            COUNT(r.rider_id) as rider_count,
            AVG(r.total_earnings) as avg_earnings,
            AVG(r.average_rating) as avg_rating
        FROM incentive_tiers it
        LEFT JOIN riders r ON it.tier_id = r.current_tier_id
        WHERE r.status = 'active'
        GROUP BY it.tier_id, it.tier_name
        ORDER BY it.tier_level ASC
        """
        return self.db.execute_query(query, fetch=True)


# ============================================================================
# EXAMPLE USAGE
# ============================================================================

def main():
    """Example usage of the Rider Incentive/Quest model"""

    # Initialize database connection
    db = DatabaseConnection(
        host='localhost',
        user='root',
        password='your_password',
        database='rider_incentive_db'
    )

    try:
        db.connect()

        # Initialize managers
        rider_mgr = RiderManager(db)
        quest_mgr = QuestManager(db)
        reward_mgr = RewardManager(db)
        analytics = Analytics(db)

        # Example 1: Get top riders
        print("=== TOP 10 RIDERS ===")
        top_riders = rider_mgr.get_top_riders(10)
        for rider in top_riders:
            print(f"{rider['rank']}. {rider['rider_name']} ({rider['tier_name']}) - "
                  f"${rider['total_earnings']} | {rider['total_quests_completed']} quests")

        # Example 2: Get active quests
        print("\n=== ACTIVE QUESTS ===")
        active_quests = quest_mgr.get_active_quests()
        for quest in active_quests:
            print(f"{quest['quest_code']}: {quest['quest_name']} "
                  f"({quest['difficulty_level']}) - ${quest['base_reward_amount']}")

        # Example 3: Get tier distribution
        print("\n=== TIER DISTRIBUTION ===")
        tiers = analytics.get_tier_distribution()
        for tier in tiers:
            print(f"{tier['tier_name']}: {tier['rider_count']} riders, "
                  f"avg earnings ${tier['avg_earnings']}")

        # Example 4: Get at-risk riders
        print("\n=== AT-RISK RIDERS (30+ days inactive) ===")
        at_risk = analytics.get_at_risk_riders(30)
        for rider in at_risk[:5]:
            print(f"{rider['rider_code']}: {rider['rider_name']} "
                  f"({rider['days_inactive']} days inactive)")

        # Example 5: Get monthly earnings
        print("\n=== SEPTEMBER 2026 EARNINGS ===")
        earnings = reward_mgr.get_monthly_earnings(2026, 9)
        if earnings:
            print(f"Active Riders: {earnings['active_riders']}")
            print(f"Total Completions: {earnings['total_completions']}")
            print(f"Total Rewards: ${earnings['total_rewards']}")
            print(f"Avg per Completion: ${earnings['avg_reward_per_completion']}")

    except Error as e:
        logger.error(f"Error: {e}")
    finally:
        db.disconnect()


if __name__ == '__main__':
    main()
