"""
Rider Incentive/Quest System - Production REST API Server
Flask-based API with comprehensive endpoints for riders, quests, and analytics
"""

from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from datetime import datetime, timedelta
import mysql.connector
from mysql.connector import Error
import os
import logging
import json
from functools import wraps
from typing import Dict, List, Optional, Tuple

# ============================================================================
# CONFIGURATION
# ============================================================================

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(
    level=os.getenv('LOG_LEVEL', 'INFO'),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Rate limiting
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', ''),
    'database': os.getenv('DB_NAME', 'rider_incentive_db'),
    'port': int(os.getenv('DB_PORT', 3306))
}

API_KEY = os.getenv('API_KEY', 'dev-api-key')

# ============================================================================
# DATABASE CONNECTION POOL
# ============================================================================

class DatabasePool:
    """Database connection pool management"""

    def __init__(self, config, pool_size=5):
        self.config = config
        self.pool_size = pool_size
        self.connections = []
        self.initialize_pool()

    def initialize_pool(self):
        """Initialize connection pool"""
        try:
            for _ in range(self.pool_size):
                conn = mysql.connector.connect(**self.config)
                self.connections.append(conn)
            logger.info(f"Database pool initialized with {self.pool_size} connections")
        except Error as e:
            logger.error(f"Failed to initialize database pool: {e}")
            raise

    def get_connection(self):
        """Get a connection from the pool"""
        if not self.connections:
            try:
                conn = mysql.connector.connect(**self.config)
                return conn
            except Error as e:
                logger.error(f"Failed to create new connection: {e}")
                raise
        return self.connections.pop(0)

    def return_connection(self, conn):
        """Return a connection to the pool"""
        if len(self.connections) < self.pool_size:
            self.connections.append(conn)
        else:
            try:
                conn.close()
            except:
                pass

    def close_all(self):
        """Close all connections"""
        for conn in self.connections:
            try:
                conn.close()
            except:
                pass
        self.connections.clear()

# Initialize database pool
db_pool = DatabasePool(DB_CONFIG)

# ============================================================================
# AUTHENTICATION
# ============================================================================

def require_api_key(f):
    """Decorator to require API key"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        api_key = request.headers.get('X-API-Key')
        if api_key != API_KEY:
            return jsonify({'error': 'Unauthorized'}), 401
        return f(*args, **kwargs)
    return decorated_function

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def execute_query(query: str, params: Tuple = None, fetch: bool = False) -> any:
    """Execute a database query"""
    conn = db_pool.get_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(query, params or ())

        if fetch:
            results = cursor.fetchall()
            cursor.close()
            return results
        else:
            conn.commit()
            affected = cursor.rowcount
            cursor.close()
            return affected
    except Error as e:
        conn.rollback()
        logger.error(f"Query error: {e}")
        raise
    finally:
        db_pool.return_connection(conn)

def dict_to_json(data):
    """Convert database results to JSON-serializable format"""
    if isinstance(data, list):
        return [dict_to_json(item) for item in data]
    elif isinstance(data, dict):
        result = {}
        for key, value in data.items():
            if isinstance(value, (datetime, timedelta)):
                result[key] = str(value)
            else:
                result[key] = value
        return result
    return data

# ============================================================================
# HEALTH & STATUS ENDPOINTS
# ============================================================================

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        # Test database connection
        execute_query("SELECT 1")

        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat(),
            'version': '1.0.0'
        }), 200
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 503

@app.route('/api/v1/status', methods=['GET'])
def api_status():
    """Get API status and statistics"""
    try:
        stats = {
            'riders': execute_query("SELECT COUNT(*) as count FROM riders")[0]['count'],
            'active_quests': execute_query("SELECT COUNT(*) as count FROM quests WHERE status='active'")[0]['count'],
            'total_earnings': execute_query("SELECT COALESCE(SUM(total_earnings), 0) as total FROM riders")[0]['total'],
            'average_rating': execute_query("SELECT COALESCE(AVG(average_rating), 0) as avg FROM riders")[0]['avg']
        }

        return jsonify({
            'status': 'operational',
            'statistics': stats,
            'timestamp': datetime.utcnow().isoformat()
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ============================================================================
# RIDER ENDPOINTS
# ============================================================================

@app.route('/api/v1/riders', methods=['GET'])
@limiter.limit("100 per hour")
def get_riders():
    """Get all riders with pagination"""
    try:
        page = request.args.get('page', 1, type=int)
        limit = request.args.get('limit', 20, type=int)
        tier_filter = request.args.get('tier')

        offset = (page - 1) * limit

        # Build query
        where_clause = ""
        params = []

        if tier_filter:
            where_clause = "WHERE current_tier_id = %s"
            params = [tier_filter]

        query = f"""
        SELECT r.*, it.tier_name
        FROM riders r
        JOIN incentive_tiers it ON r.current_tier_id = it.tier_id
        {where_clause}
        ORDER BY r.total_earnings DESC
        LIMIT %s OFFSET %s
        """
        params.extend([limit, offset])

        riders = execute_query(query, tuple(params), fetch=True)

        # Get total count
        count_query = f"SELECT COUNT(*) as count FROM riders {where_clause}"
        total = execute_query(count_query, tuple(params[:-2] if params else []), fetch=True)[0]['count']

        return jsonify({
            'data': dict_to_json(riders),
            'pagination': {
                'page': page,
                'limit': limit,
                'total': total,
                'pages': (total + limit - 1) // limit
            }
        }), 200
    except Exception as e:
        logger.error(f"Error fetching riders: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/riders/<int:rider_id>', methods=['GET'])
@limiter.limit("200 per hour")
def get_rider(rider_id):
    """Get specific rider details"""
    try:
        query = """
        SELECT r.*, it.tier_name, rs.*
        FROM riders r
        JOIN incentive_tiers it ON r.current_tier_id = it.tier_id
        LEFT JOIN rider_stats rs ON r.rider_id = rs.rider_id
        WHERE r.rider_id = %s
        """

        result = execute_query(query, (rider_id,), fetch=True)

        if not result:
            return jsonify({'error': 'Rider not found'}), 404

        return jsonify(dict_to_json(result[0])), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/riders/<int:rider_id>/stats', methods=['GET'])
def get_rider_stats(rider_id):
    """Get rider statistics"""
    try:
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
            rs.earnings_this_week,
            rs.consecutive_completed_quests,
            MAX(qc.completion_date) as last_activity
        FROM riders r
        JOIN incentive_tiers it ON r.current_tier_id = it.tier_id
        LEFT JOIN rider_stats rs ON r.rider_id = rs.rider_id
        LEFT JOIN quest_completions qc ON r.rider_id = qc.rider_id
        WHERE r.rider_id = %s
        GROUP BY r.rider_id
        """

        result = execute_query(query, (rider_id,), fetch=True)

        if not result:
            return jsonify({'error': 'Rider not found'}), 404

        return jsonify(dict_to_json(result[0])), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ============================================================================
# QUEST ENDPOINTS
# ============================================================================

@app.route('/api/v1/quests', methods=['GET'])
@limiter.limit("100 per hour")
def get_quests():
    """Get quests with filtering"""
    try:
        status_filter = request.args.get('status', 'active')
        difficulty = request.args.get('difficulty')

        where_clause = "WHERE status = %s"
        params = [status_filter]

        if difficulty:
            where_clause += " AND difficulty_level = %s"
            params.append(difficulty)

        query = f"""
        SELECT q.*, qt.type_name,
               COUNT(DISTINCT qp.rider_id) as participant_count,
               SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END) as completion_count
        FROM quests q
        LEFT JOIN quest_types qt ON q.quest_type_id = qt.quest_type_id
        LEFT JOIN quest_participants qp ON q.quest_id = qp.quest_id
        {where_clause}
        GROUP BY q.quest_id
        ORDER BY q.start_date DESC
        """

        quests = execute_query(query, tuple(params), fetch=True)

        return jsonify({'data': dict_to_json(quests)}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/quests/<int:quest_id>', methods=['GET'])
def get_quest(quest_id):
    """Get specific quest details"""
    try:
        query = """
        SELECT q.*, qt.type_name,
               COUNT(DISTINCT qp.rider_id) as participant_count,
               SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END) as completion_count,
               ROUND(100.0 * SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END)
                     / NULLIF(COUNT(DISTINCT qp.rider_id), 0), 2) as completion_rate
        FROM quests q
        LEFT JOIN quest_types qt ON q.quest_type_id = qt.quest_type_id
        LEFT JOIN quest_participants qp ON q.quest_id = qp.quest_id
        WHERE q.quest_id = %s
        GROUP BY q.quest_id
        """

        result = execute_query(query, (quest_id,), fetch=True)

        if not result:
            return jsonify({'error': 'Quest not found'}), 404

        return jsonify(dict_to_json(result[0])), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ============================================================================
# ENROLLMENT ENDPOINTS
# ============================================================================

@app.route('/api/v1/riders/<int:rider_id>/enroll', methods=['POST'])
@require_api_key
@limiter.limit("50 per hour")
def enroll_rider(rider_id):
    """Enroll a rider in a quest"""
    try:
        data = request.get_json()
        quest_id = data.get('quest_id')

        if not quest_id:
            return jsonify({'error': 'quest_id required'}), 400

        # Check if already enrolled
        existing = execute_query(
            "SELECT COUNT(*) as count FROM quest_participants WHERE rider_id = %s AND quest_id = %s",
            (rider_id, quest_id),
            fetch=True
        )

        if existing[0]['count'] > 0:
            return jsonify({'error': 'Already enrolled in this quest'}), 409

        # Enroll
        execute_query(
            """
            INSERT INTO quest_participants (rider_id, quest_id, participation_status, enrollment_date)
            VALUES (%s, %s, 'enrolled', NOW())
            """,
            (rider_id, quest_id)
        )

        logger.info(f"Rider {rider_id} enrolled in quest {quest_id}")

        return jsonify({
            'message': 'Successfully enrolled',
            'rider_id': rider_id,
            'quest_id': quest_id
        }), 201
    except Exception as e:
        logger.error(f"Enrollment error: {e}")
        return jsonify({'error': str(e)}), 500

# ============================================================================
# COMPLETION ENDPOINTS
# ============================================================================

@app.route('/api/v1/riders/<int:rider_id>/quests/<int:quest_id>/complete', methods=['POST'])
@require_api_key
@limiter.limit("50 per hour")
def complete_quest(rider_id, quest_id):
    """Record a completed quest"""
    try:
        data = request.get_json()
        quality_rating = data.get('quality_rating', 4)
        completion_time_hours = data.get('completion_time_hours', 1.0)

        # Get participant ID
        participant = execute_query(
            "SELECT participant_id FROM quest_participants WHERE rider_id = %s AND quest_id = %s",
            (rider_id, quest_id),
            fetch=True
        )

        if not participant:
            return jsonify({'error': 'Participant not found'}), 404

        participant_id = participant[0]['participant_id']

        # Get quest and tier info
        rider_info = execute_query(
            """
            SELECT r.current_tier_id, q.base_reward_amount
            FROM riders r
            CROSS JOIN quests q
            WHERE r.rider_id = %s AND q.quest_id = %s
            """,
            (rider_id, quest_id),
            fetch=True
        )

        tier_info = execute_query(
            "SELECT bonus_multiplier FROM incentive_tiers WHERE tier_id = %s",
            (rider_info[0]['current_tier_id'],),
            fetch=True
        )

        base_reward = rider_info[0]['base_reward_amount']
        tier_multiplier = tier_info[0]['bonus_multiplier']
        total_reward = base_reward * tier_multiplier
        tier_bonus = base_reward * (tier_multiplier - 1)

        # Record completion
        execute_query(
            """
            INSERT INTO quest_completions
            (participant_id, rider_id, quest_id, completion_date, completion_time_hours,
             quality_rating, reward_earned, tier_bonus_applied)
            VALUES (%s, %s, %s, NOW(), %s, %s, %s, %s)
            """,
            (participant_id, rider_id, quest_id, completion_time_hours, quality_rating,
             base_reward, tier_bonus)
        )

        # Create payout
        completion = execute_query(
            "SELECT completion_id FROM quest_completions WHERE participant_id = %s ORDER BY completion_date DESC LIMIT 1",
            (participant_id,),
            fetch=True
        )

        execute_query(
            """
            INSERT INTO reward_payouts
            (rider_id, completion_id, quest_id, reward_type_id, reward_amount,
             payout_status, payment_method)
            SELECT %s, %s, %s, reward_type_id, %s, 'pending', 'wallet'
            FROM reward_types WHERE type_name = 'Cash Bonus' LIMIT 1
            """,
            (rider_id, completion[0]['completion_id'], quest_id, total_reward)
        )

        # Update participant status
        execute_query(
            "UPDATE quest_participants SET participation_status = 'completed' WHERE participant_id = %s",
            (participant_id,)
        )

        # Update rider stats
        execute_query(
            """
            UPDATE riders
            SET total_quests_completed = total_quests_completed + 1,
                total_earnings = total_earnings + %s,
                average_rating = (
                    SELECT AVG(quality_rating) FROM quest_completions WHERE rider_id = %s
                )
            WHERE rider_id = %s
            """,
            (total_reward, rider_id, rider_id)
        )

        logger.info(f"Quest {quest_id} completed by rider {rider_id}, reward: ${total_reward}")

        return jsonify({
            'message': 'Quest completed successfully',
            'completion_id': completion[0]['completion_id'],
            'reward': {
                'base': base_reward,
                'tier_bonus': tier_bonus,
                'total': total_reward
            }
        }), 201
    except Exception as e:
        logger.error(f"Completion error: {e}")
        return jsonify({'error': str(e)}), 500

# ============================================================================
# ANALYTICS ENDPOINTS
# ============================================================================

@app.route('/api/v1/analytics/leaderboard', methods=['GET'])
@limiter.limit("50 per hour")
def leaderboard():
    """Get top riders leaderboard"""
    try:
        limit = request.args.get('limit', 20, type=int)

        query = """
        SELECT
            r.rider_code,
            CONCAT(r.first_name, ' ', r.last_name) as rider_name,
            it.tier_name,
            r.total_quests_completed,
            r.average_rating,
            r.total_earnings,
            RANK() OVER (ORDER BY r.total_earnings DESC) as earnings_rank
        FROM riders r
        JOIN incentive_tiers it ON r.current_tier_id = it.tier_id
        WHERE r.status = 'active'
        ORDER BY r.total_earnings DESC
        LIMIT %s
        """

        results = execute_query(query, (limit,), fetch=True)

        return jsonify({'data': dict_to_json(results)}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/analytics/tiers', methods=['GET'])
@limiter.limit("50 per hour")
def tier_distribution():
    """Get tier distribution analytics"""
    try:
        query = """
        SELECT
            it.tier_name,
            it.tier_level,
            COUNT(r.rider_id) as rider_count,
            AVG(r.total_earnings) as avg_earnings,
            AVG(r.average_rating) as avg_rating,
            SUM(r.total_quests_completed) as total_quests
        FROM incentive_tiers it
        LEFT JOIN riders r ON it.tier_id = r.current_tier_id AND r.status = 'active'
        GROUP BY it.tier_id, it.tier_name, it.tier_level
        ORDER BY it.tier_level ASC
        """

        results = execute_query(query, fetch=True)

        return jsonify({'data': dict_to_json(results)}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/analytics/quests', methods=['GET'])
@limiter.limit("50 per hour")
def quest_analytics():
    """Get quest performance analytics"""
    try:
        query = """
        SELECT
            q.quest_code,
            q.quest_name,
            q.difficulty_level,
            COUNT(DISTINCT qp.rider_id) as participants,
            SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END) as completions,
            ROUND(100.0 * SUM(CASE WHEN qp.participation_status = 'completed' THEN 1 ELSE 0 END)
                  / NULLIF(COUNT(DISTINCT qp.rider_id), 0), 2) as completion_rate,
            AVG(qc.quality_rating) as avg_rating,
            SUM(qc.reward_earned + qc.tier_bonus_applied) as total_rewards
        FROM quests q
        LEFT JOIN quest_participants qp ON q.quest_id = qp.quest_id
        LEFT JOIN quest_completions qc ON qp.participant_id = qc.participant_id
        WHERE q.status = 'active'
        GROUP BY q.quest_id
        ORDER BY completion_rate DESC
        """

        results = execute_query(query, fetch=True)

        return jsonify({'data': dict_to_json(results)}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ============================================================================
# PAYOUT ENDPOINTS
# ============================================================================

@app.route('/api/v1/payouts/pending', methods=['GET'])
@require_api_key
@limiter.limit("50 per hour")
def pending_payouts():
    """Get pending payouts"""
    try:
        query = """
        SELECT rp.*, r.rider_code, CONCAT(r.first_name, ' ', r.last_name) as rider_name
        FROM reward_payouts rp
        JOIN riders r ON rp.rider_id = r.rider_id
        WHERE rp.payout_status = 'pending'
        ORDER BY rp.created_at ASC
        """

        results = execute_query(query, fetch=True)

        return jsonify({'data': dict_to_json(results), 'count': len(results)}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/payouts/<int:payout_id>/process', methods=['POST'])
@require_api_key
@limiter.limit("50 per hour")
def process_payout(payout_id):
    """Process a pending payout"""
    try:
        execute_query(
            """
            UPDATE reward_payouts
            SET payout_status = 'processed', payout_date = NOW()
            WHERE payout_id = %s AND payout_status = 'pending'
            """,
            (payout_id,)
        )

        logger.info(f"Payout {payout_id} processed")

        return jsonify({'message': 'Payout processed successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ============================================================================
# ERROR HANDLERS
# ============================================================================

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def server_error(error):
    logger.error(f"Server error: {error}")
    return jsonify({'error': 'Internal server error'}), 500

@app.errorhandler(429)
def ratelimit_handler(e):
    return jsonify({'error': 'Rate limit exceeded', 'description': str(e.description)}), 429

# ============================================================================
# STARTUP & SHUTDOWN
# ============================================================================

@app.before_request
def before_request():
    """Log incoming requests"""
    logger.debug(f"{request.method} {request.path}")

@app.teardown_appcontext
def close_db(error):
    """Close database connection"""
    pass  # Connection pooling handles this

if __name__ == '__main__':
    try:
        # Test database connection
        execute_query("SELECT 1")
        logger.info("Database connection successful")

        # Start server
        port = int(os.getenv('PORT', 5000))
        debug = os.getenv('FLASK_ENV') == 'development'

        logger.info(f"Starting API server on port {port}")
        app.run(host='0.0.0.0', port=port, debug=debug)
    except Exception as e:
        logger.error(f"Failed to start server: {e}")
        raise
    finally:
        db_pool.close_all()
