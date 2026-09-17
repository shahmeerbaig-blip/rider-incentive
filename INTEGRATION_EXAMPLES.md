# Integration Examples & Real-World Use Cases

## Quick Start - API Client Setup

### 1. Basic API Client Class

```python
# api_client.py
import requests
import logging
from typing import Optional, Dict, List
from datetime import datetime

logger = logging.getLogger(__name__)

class RiderIncentiveAPIClient:
    """Client for Rider Incentive API"""
    
    def __init__(self, base_url: str = "http://localhost:5000", api_key: str = "your-api-key"):
        self.base_url = base_url
        self.api_key = api_key
        self.headers = {
            "X-API-Key": api_key,
            "Content-Type": "application/json"
        }
    
    def _make_request(self, method: str, endpoint: str, data: Optional[Dict] = None):
        """Make HTTP request to API"""
        url = f"{self.base_url}{endpoint}"
        
        try:
            if method == "GET":
                response = requests.get(url, headers=self.headers, timeout=10)
            elif method == "POST":
                response = requests.post(url, headers=self.headers, json=data, timeout=10)
            elif method == "PUT":
                response = requests.put(url, headers=self.headers, json=data, timeout=10)
            else:
                raise ValueError(f"Unsupported method: {method}")
            
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"API request failed: {e}")
            raise
    
    # ===== RIDER ENDPOINTS =====
    
    def get_riders(self, page: int = 1, limit: int = 20, tier: Optional[int] = None) -> Dict:
        """Get all riders with pagination"""
        params = f"?page={page}&limit={limit}"
        if tier:
            params += f"&tier={tier}"
        
        return self._make_request("GET", f"/api/v1/riders{params}")
    
    def get_rider(self, rider_id: int) -> Dict:
        """Get specific rider details"""
        return self._make_request("GET", f"/api/v1/riders/{rider_id}")
    
    def get_rider_stats(self, rider_id: int) -> Dict:
        """Get rider statistics"""
        return self._make_request("GET", f"/api/v1/riders/{rider_id}/stats")
    
    # ===== QUEST ENDPOINTS =====
    
    def get_quests(self, status: str = "active", difficulty: Optional[str] = None) -> Dict:
        """Get quests"""
        params = f"?status={status}"
        if difficulty:
            params += f"&difficulty={difficulty}"
        
        return self._make_request("GET", f"/api/v1/quests{params}")
    
    def get_quest(self, quest_id: int) -> Dict:
        """Get specific quest"""
        return self._make_request("GET", f"/api/v1/quests/{quest_id}")
    
    # ===== ENROLLMENT ENDPOINTS =====
    
    def enroll_rider(self, rider_id: int, quest_id: int) -> Dict:
        """Enroll rider in a quest"""
        return self._make_request(
            "POST",
            f"/api/v1/riders/{rider_id}/enroll",
            {"quest_id": quest_id}
        )
    
    # ===== COMPLETION ENDPOINTS =====
    
    def complete_quest(self, rider_id: int, quest_id: int, 
                      quality_rating: int = 4, 
                      completion_time_hours: float = 1.0) -> Dict:
        """Record completed quest"""
        return self._make_request(
            "POST",
            f"/api/v1/riders/{rider_id}/quests/{quest_id}/complete",
            {
                "quality_rating": quality_rating,
                "completion_time_hours": completion_time_hours
            }
        )
    
    # ===== ANALYTICS ENDPOINTS =====
    
    def get_leaderboard(self, limit: int = 20) -> Dict:
        """Get top riders leaderboard"""
        return self._make_request("GET", f"/api/v1/analytics/leaderboard?limit={limit}")
    
    def get_tier_distribution(self) -> Dict:
        """Get tier analytics"""
        return self._make_request("GET", "/api/v1/analytics/tiers")
    
    def get_quest_analytics(self) -> Dict:
        """Get quest performance analytics"""
        return self._make_request("GET", "/api/v1/analytics/quests")
    
    # ===== PAYOUT ENDPOINTS =====
    
    def get_pending_payouts(self) -> Dict:
        """Get pending payouts"""
        return self._make_request("GET", "/api/v1/payouts/pending")
    
    def process_payout(self, payout_id: int) -> Dict:
        """Process a payout"""
        return self._make_request("POST", f"/api/v1/payouts/{payout_id}/process")
    
    # ===== UTILITY =====
    
    def health_check(self) -> bool:
        """Check API health"""
        try:
            response = self._make_request("GET", "/health")
            return response.get("status") == "healthy"
        except:
            return False
```

---

## Use Case 1: Automated Rider Enrollment

**Scenario:** When a new rider signs up, automatically enroll them in beginner quests.

```python
# auto_enroll.py
from api_client import RiderIncentiveAPIClient
import logging

logger = logging.getLogger(__name__)
client = RiderIncentiveAPIClient(api_key="your-api-key")

def auto_enroll_new_rider(rider_id: int):
    """Automatically enroll new rider in beginner quests"""
    
    try:
        # Get all beginner quests (easy difficulty)
        quests_response = client.get_quests(status="active", difficulty="easy")
        beginner_quests = quests_response.get('data', [])
        
        logger.info(f"Found {len(beginner_quests)} beginner quests")
        
        # Enroll in first 3 quests
        for quest in beginner_quests[:3]:
            try:
                result = client.enroll_rider(rider_id, quest['quest_id'])
                logger.info(f"Enrolled rider {rider_id} in quest {quest['quest_id']}")
            except Exception as e:
                logger.warning(f"Failed to enroll in quest {quest['quest_id']}: {e}")
        
        logger.info(f"Successfully enrolled rider {rider_id}")
        
    except Exception as e:
        logger.error(f"Auto-enrollment failed for rider {rider_id}: {e}")
        raise

# Usage
if __name__ == "__main__":
    new_rider_id = 1
    auto_enroll_new_rider(new_rider_id)
```

---

## Use Case 2: Quest Completion with Reward Processing

**Scenario:** Rider completes a quest and receives reward immediately.

```python
# quest_completion.py
from api_client import RiderIncentiveAPIClient
from datetime import datetime
import logging

logger = logging.getLogger(__name__)
client = RiderIncentiveAPIClient()

def process_quest_completion(rider_id: int, quest_id: int, 
                            quality_rating: int = 5,
                            completion_time_hours: float = 0.5):
    """Process quest completion and reward"""
    
    try:
        # Record completion
        logger.info(f"Processing quest {quest_id} completion for rider {rider_id}")
        
        completion_response = client.complete_quest(
            rider_id=rider_id,
            quest_id=quest_id,
            quality_rating=quality_rating,
            completion_time_hours=completion_time_hours
        )
        
        reward = completion_response.get('reward', {})
        
        logger.info(f"Quest completed successfully")
        logger.info(f"  Base reward: ${reward.get('base', 0)}")
        logger.info(f"  Tier bonus: ${reward.get('tier_bonus', 0)}")
        logger.info(f"  Total reward: ${reward.get('total', 0)}")
        
        # Verify completion in rider stats
        stats = client.get_rider_stats(rider_id)
        
        logger.info(f"Rider updated stats:")
        logger.info(f"  Total quests completed: {stats.get('total_quests_completed')}")
        logger.info(f"  Total earnings: ${stats.get('total_earnings')}")
        logger.info(f"  Average rating: {stats.get('average_quality_rating')}")
        
        return completion_response
        
    except Exception as e:
        logger.error(f"Failed to process completion: {e}")
        raise

# Usage
if __name__ == "__main__":
    process_quest_completion(
        rider_id=1,
        quest_id=1,
        quality_rating=5,
        completion_time_hours=1.5
    )
```

---

## Use Case 3: Daily Payout Processing

**Scenario:** Process all pending payouts daily at 2 AM.

```python
# daily_payout_processor.py
from api_client import RiderIncentiveAPIClient
from apscheduler.schedulers.background import BackgroundScheduler
import logging

logger = logging.getLogger(__name__)
client = RiderIncentiveAPIClient(api_key="your-api-key")

class PayoutProcessor:
    def __init__(self):
        self.scheduler = BackgroundScheduler()
    
    def process_pending_payouts(self):
        """Process all pending payouts"""
        
        logger.info("=== Starting Payout Processing ===")
        
        try:
            # Get pending payouts
            payouts_response = client.get_pending_payouts()
            payouts = payouts_response.get('data', [])
            
            logger.info(f"Found {len(payouts)} pending payouts")
            
            processed = 0
            failed = 0
            total_amount = 0
            
            for payout in payouts:
                payout_id = payout['payout_id']
                amount = payout['reward_amount']
                rider_name = payout.get('rider_name', 'Unknown')
                
                try:
                    # Process payout
                    client.process_payout(payout_id)
                    processed += 1
                    total_amount += amount
                    
                    logger.info(f"✓ Processed payout {payout_id}: {rider_name} - ${amount}")
                    
                except Exception as e:
                    failed += 1
                    logger.error(f"✗ Failed to process payout {payout_id}: {e}")
            
            # Summary
            logger.info("=== Payout Processing Summary ===")
            logger.info(f"Total payouts: {len(payouts)}")
            logger.info(f"Processed: {processed}")
            logger.info(f"Failed: {failed}")
            logger.info(f"Total amount: ${total_amount:.2f}")
            
            return {
                'total': len(payouts),
                'processed': processed,
                'failed': failed,
                'total_amount': total_amount
            }
            
        except Exception as e:
            logger.error(f"Payout processing failed: {e}")
            raise
    
    def schedule_daily(self):
        """Schedule daily payout processing at 2 AM"""
        self.scheduler.add_job(
            self.process_pending_payouts,
            'cron',
            hour=2,
            minute=0,
            id='daily_payout_processor'
        )
        self.scheduler.start()
        logger.info("Daily payout processor scheduled")

# Usage
if __name__ == "__main__":
    processor = PayoutProcessor()
    processor.schedule_daily()
    
    # Keep running
    try:
        while True:
            pass
    except KeyboardInterrupt:
        processor.scheduler.shutdown()
```

---

## Use Case 4: Real-Time Leaderboard Updates

**Scenario:** Display live leaderboard on dashboard, updated every 5 seconds.

```python
# leaderboard_service.py
from api_client import RiderIncentiveAPIClient
import logging
from datetime import datetime

logger = logging.getLogger(__name__)
client = RiderIncentiveAPIClient()

class LeaderboardService:
    def __init__(self, cache_ttl_seconds: int = 30):
        self.cache_ttl_seconds = cache_ttl_seconds
        self.cache = None
        self.cache_time = None
    
    def get_leaderboard(self, limit: int = 20, force_refresh: bool = False) -> list:
        """Get leaderboard with caching"""
        
        import time
        now = time.time()
        
        # Return cached if valid and not forced refresh
        if (self.cache is not None and 
            self.cache_time is not None and
            not force_refresh and
            (now - self.cache_time) < self.cache_ttl_seconds):
            
            logger.debug("Returning cached leaderboard")
            return self.cache
        
        # Fetch fresh data
        logger.info(f"Fetching fresh leaderboard (top {limit})")
        
        try:
            response = client.get_leaderboard(limit=limit)
            self.cache = response.get('data', [])
            self.cache_time = now
            
            # Log top 3
            for i, rider in enumerate(self.cache[:3], 1):
                logger.info(f"{i}. {rider['rider_name']} - ${rider['total_earnings']} ({rider['tier_name']})")
            
            return self.cache
            
        except Exception as e:
            logger.error(f"Failed to fetch leaderboard: {e}")
            # Return cached as fallback
            return self.cache or []
    
    def get_top_rider(self) -> dict:
        """Get #1 rider"""
        leaderboard = self.get_leaderboard(limit=1)
        return leaderboard[0] if leaderboard else {}
    
    def get_rider_rank(self, rider_id: int) -> dict:
        """Get specific rider's rank and stats"""
        leaderboard = self.get_leaderboard(limit=100)
        
        for rank, rider in enumerate(leaderboard, 1):
            if rider['rider_id'] == rider_id:
                return {
                    'rank': rank,
                    'rider': rider
                }
        
        return None

# Usage in Flask app
from flask import Flask, jsonify
from leaderboard_service import LeaderboardService

app = Flask(__name__)
leaderboard_service = LeaderboardService(cache_ttl_seconds=30)

@app.route('/dashboard/leaderboard')
def leaderboard():
    data = leaderboard_service.get_leaderboard(limit=20)
    return jsonify({'data': data})

@app.route('/dashboard/top-rider')
def top_rider():
    rider = leaderboard_service.get_top_rider()
    return jsonify(rider)
```

---

## Use Case 5: Automated Tier Promotions

**Scenario:** Check riders daily and promote those who meet tier requirements.

```python
# tier_promotion.py
from api_client import RiderIncentiveAPIClient
import logging

logger = logging.getLogger(__name__)
client = RiderIncentiveAPIClient(api_key="your-api-key")

class TierPromotionEngine:
    """Automatically promote riders to higher tiers"""
    
    # Tier requirements (can be fetched from API)
    TIER_REQUIREMENTS = {
        1: {'name': 'Bronze', 'min_quests': 0, 'min_rating': 0.0},
        2: {'name': 'Silver', 'min_quests': 25, 'min_rating': 3.8},
        3: {'name': 'Gold', 'min_quests': 100, 'min_rating': 4.2},
        4: {'name': 'Platinum', 'min_quests': 250, 'min_rating': 4.5},
        5: {'name': 'Diamond', 'min_quests': 500, 'min_rating': 4.7}
    }
    
    def check_and_promote_riders(self):
        """Check all active riders and promote if eligible"""
        
        logger.info("=== Starting Tier Promotion Check ===")
        
        try:
            # Get all riders
            riders_response = client.get_riders(limit=1000)
            riders = riders_response.get('data', [])
            
            logger.info(f"Checking {len(riders)} riders for promotion")
            
            promoted = 0
            
            for rider in riders:
                if self._should_promote(rider):
                    if self._promote_rider(rider):
                        promoted += 1
            
            logger.info(f"=== Promotion Complete: {promoted} riders promoted ===")
            return promoted
            
        except Exception as e:
            logger.error(f"Tier promotion failed: {e}")
            raise
    
    def _should_promote(self, rider: dict) -> bool:
        """Check if rider should be promoted"""
        
        current_tier = rider['current_tier_id']
        quests_completed = rider['total_quests_completed']
        rating = rider['average_rating']
        
        # Find next tier
        next_tier_id = current_tier + 1
        
        if next_tier_id not in self.TIER_REQUIREMENTS:
            # Already at max tier
            return False
        
        tier_req = self.TIER_REQUIREMENTS[next_tier_id]
        
        # Check if meets requirements
        meets_quests = quests_completed >= tier_req['min_quests']
        meets_rating = rating >= tier_req['min_rating']
        
        if meets_quests and meets_rating:
            logger.info(f"Rider {rider['rider_code']} eligible for promotion to {tier_req['name']}")
            return True
        
        return False
    
    def _promote_rider(self, rider: dict) -> bool:
        """Promote rider to next tier"""
        
        rider_id = rider['rider_id']
        rider_name = f"{rider['first_name']} {rider['last_name']}"
        current_tier = rider['current_tier_id']
        next_tier = current_tier + 1
        next_tier_name = self.TIER_REQUIREMENTS[next_tier]['name']
        
        try:
            # In production, this would be an API endpoint
            # For now, we log the promotion
            logger.info(f"✓ PROMOTED: {rider_name} ({rider['rider_code']}) to {next_tier_name}")
            
            # You would call an API endpoint like:
            # client.promote_rider(rider_id, next_tier)
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to promote rider {rider_id}: {e}")
            return False

# Schedule daily
from apscheduler.schedulers.background import BackgroundScheduler

scheduler = BackgroundScheduler()
engine = TierPromotionEngine()

scheduler.add_job(
    engine.check_and_promote_riders,
    'cron',
    hour=3,  # 3 AM
    minute=0
)
scheduler.start()

logger.info("Tier promotion engine scheduled for 3 AM daily")
```

---

## Use Case 6: Analytics Dashboard Integration

**Scenario:** Fetch and display real-time analytics.

```python
# dashboard_service.py
from api_client import RiderIncentiveAPIClient
import json
from datetime import datetime

class DashboardService:
    def __init__(self):
        self.client = RiderIncentiveAPIClient()
    
    def get_dashboard_data(self):
        """Get all dashboard data in one call"""
        
        return {
            'timestamp': datetime.utcnow().isoformat(),
            'leaderboard': self.client.get_leaderboard(limit=10).get('data', []),
            'tier_distribution': self.client.get_tier_distribution().get('data', []),
            'quest_performance': self.client.get_quest_analytics().get('data', [])[:10],
            'health': self._get_health()
        }
    
    def _get_health(self):
        """Get system health"""
        try:
            return {
                'status': 'healthy' if self.client.health_check() else 'degraded'
            }
        except:
            return {'status': 'unhealthy'}

# Flask integration
from flask import Flask, jsonify, render_template

app = Flask(__name__)
dashboard_service = DashboardService()

@app.route('/api/dashboard')
def dashboard_api():
    data = dashboard_service.get_dashboard_data()
    return jsonify(data)

@app.route('/dashboard')
def dashboard():
    return render_template('dashboard.html')
```

---

## Testing the Integration

```python
# test_integration.py
import unittest
from api_client import RiderIncentiveAPIClient

class TestAPIIntegration(unittest.TestCase):
    
    def setUp(self):
        self.client = RiderIncentiveAPIClient(api_key="test-api-key")
    
    def test_health_check(self):
        """Test API health"""
        self.assertTrue(self.client.health_check())
    
    def test_get_riders(self):
        """Test getting riders"""
        response = self.client.get_riders(limit=5)
        self.assertIn('data', response)
        self.assertIsInstance(response['data'], list)
    
    def test_get_quests(self):
        """Test getting quests"""
        response = self.client.get_quests(status="active")
        self.assertIn('data', response)
    
    def test_enroll_rider(self):
        """Test rider enrollment"""
        response = self.client.enroll_rider(rider_id=1, quest_id=1)
        self.assertEqual(response['rider_id'], 1)
    
    def test_complete_quest(self):
        """Test quest completion"""
        response = self.client.complete_quest(
            rider_id=1,
            quest_id=1,
            quality_rating=5
        )
        self.assertIn('reward', response)

if __name__ == '__main__':
    unittest.main()
```

---

## Deployment Checklist

- [ ] Configure `.env` with production credentials
- [ ] Install dependencies: `pip install -r requirements.txt`
- [ ] Run tests: `pytest test_integration.py`
- [ ] Build Docker image: `docker-compose build`
- [ ] Start services: `docker-compose up -d`
- [ ] Verify API: `curl http://localhost:5000/health`
- [ ] Test endpoints with sample API client
- [ ] Set up scheduled tasks (tier promotion, payouts)
- [ ] Configure monitoring and logging
- [ ] Deploy dashboard

---

*Integration Guide v1.0*
*Last Updated: 2026-09-17*
