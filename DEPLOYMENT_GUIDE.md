# Production Deployment & Integration Guide

## Overview

This guide covers deploying the Rider Incentive/Quest system to production with:
- Docker containerization
- Database migration and backup
- API server setup
- Monitoring & logging
- CI/CD pipeline

---

## Part 1: Prerequisites

### System Requirements
```
CPU:       2+ cores
Memory:    4GB+ RAM
Disk:      50GB+ storage
OS:        Ubuntu 20.04+ / CentOS 8+ / macOS 11+
Database:  MySQL 8.0+
Python:    3.9+
```

### Tools Installation

#### Ubuntu/Debian
```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
sudo apt-get install -y docker.io docker-compose

# Install Python & pip
sudo apt-get install -y python3.9 python3-pip python3-venv

# Install MySQL client
sudo apt-get install -y mysql-client

# Verify installations
docker --version
python3 --version
mysql --version
```

#### macOS
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
brew install --cask docker

# Install Python
brew install python@3.9

# Install MySQL client
brew install mysql-client

# Verify
docker --version
python3 --version
mysql --version
```

---

## Part 2: Docker Setup

### Create Dockerfile for App

```dockerfile
# Dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health')"

# Run application
CMD ["python", "api_server.py"]
```

### Create docker-compose.yml

```yaml
# docker-compose.yml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: rider_incentive_db
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: rider_incentive_db
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./rider_incentive_schema.sql:/docker-entrypoint-initdb.d/schema.sql
      - ./populate_global_incentive_schemes.sql:/docker-entrypoint-initdb.d/data.sql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - incentive_network

  api:
    build: .
    container_name: rider_incentive_api
    depends_on:
      mysql:
        condition: service_healthy
    environment:
      DB_HOST: mysql
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      DB_NAME: rider_incentive_db
      FLASK_ENV: production
      API_KEY: ${API_KEY}
    ports:
      - "5000:5000"
    volumes:
      - ./logs:/app/logs
    networks:
      - incentive_network
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    container_name: rider_incentive_nginx
    depends_on:
      - api
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - ./static:/usr/share/nginx/html:ro
    networks:
      - incentive_network
    restart: unless-stopped

volumes:
  mysql_data:

networks:
  incentive_network:
    driver: bridge
```

### Create .env.example

```bash
# .env.example (rename to .env in production)
DB_ROOT_PASSWORD=your_secure_root_password
DB_USER=incentive_user
DB_PASSWORD=your_secure_user_password
FLASK_ENV=production
API_KEY=your_secure_api_key_here
LOG_LEVEL=INFO
```

---

## Part 3: Database Setup

### Create migration scripts

#### migration_001_initial.sql
```sql
-- Initial database creation (already handled by schema.sql)
-- This file ensures idempotent migrations

-- Check if tables exist
SELECT 'Database initialized successfully' as status;

-- Verify all 10 tables
SELECT COUNT(*) as table_count FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'rider_incentive_db';
```

#### migration_002_add_audit_tables.sql
```sql
-- Add audit tables for compliance

CREATE TABLE IF NOT EXISTS riders_audit (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    rider_id INT NOT NULL,
    action VARCHAR(50),
    old_tier_id INT,
    new_tier_id INT,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (rider_id) REFERENCES riders(rider_id)
);

CREATE TABLE IF NOT EXISTS payouts_audit (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    payout_id INT NOT NULL,
    action VARCHAR(50),
    old_status VARCHAR(50),
    new_status VARCHAR(50),
    amount DECIMAL(12,2),
    processed_by VARCHAR(100),
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (payout_id) REFERENCES reward_payouts(payout_id)
);

CREATE INDEX idx_riders_audit_date ON riders_audit(changed_at);
CREATE INDEX idx_payouts_audit_date ON payouts_audit(processed_at);
```

### Database Backup Script

```bash
#!/bin/bash
# backup_db.sh

BACKUP_DIR="/backups/rider_incentive"
DB_NAME="rider_incentive_db"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql"

# Create backup directory
mkdir -p $BACKUP_DIR

# Perform backup
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME > $BACKUP_FILE

# Compress
gzip $BACKUP_FILE

# Keep only last 30 days of backups
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_FILE.gz"
```

### Database Restore Script

```bash
#!/bin/bash
# restore_db.sh

BACKUP_FILE=$1
DB_NAME="rider_incentive_db"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: ./restore_db.sh <backup_file>"
    exit 1
fi

# Check if file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Decompress if needed
if [[ $BACKUP_FILE == *.gz ]]; then
    TEMP_FILE="${BACKUP_FILE%.gz}"
    gunzip -c "$BACKUP_FILE" > "$TEMP_FILE"
    BACKUP_FILE="$TEMP_FILE"
fi

# Restore database
mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME < $BACKUP_FILE

echo "Database restored from: $BACKUP_FILE"
```

---

## Part 4: Deployment Steps

### Step 1: Prepare Server

```bash
# SSH into server
ssh user@production_server

# Clone repository
git clone https://github.com/yourorg/rider_incentive.git
cd rider_incentive

# Create environment file
cp .env.example .env
# Edit .env with production values
nano .env

# Create backup directory
mkdir -p /backups/rider_incentive
chmod 700 /backups/rider_incentive
```

### Step 2: Build and Start Containers

```bash
# Build Docker images
docker-compose build

# Start services
docker-compose up -d

# Verify services are running
docker-compose ps
# Output should show all containers "healthy" or "up"

# Check logs
docker-compose logs -f api

# Wait for database initialization (~30 seconds)
sleep 30

# Verify database connection
docker exec rider_incentive_api python -c "
from database import get_connection
conn = get_connection()
cursor = conn.cursor()
cursor.execute('SELECT COUNT(*) FROM riders')
print(f'Riders in database: {cursor.fetchone()[0]}')
conn.close()
"
```

### Step 3: Initialize and Verify

```bash
# Run migrations
docker exec rider_incentive_api python -m alembic upgrade head

# Run health checks
curl http://localhost:5000/health

# Check API endpoints
curl http://localhost:5000/api/v1/riders
curl http://localhost:5000/api/v1/quests/active

# View logs
docker-compose logs mysql
docker-compose logs api
```

### Step 4: Setup Monitoring

```bash
# Install Prometheus
docker pull prom/prometheus

# Create prometheus.yml
cat > prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'api'
    static_configs:
      - targets: ['localhost:5000']
EOF

# Start Prometheus
docker run -d --name prometheus -p 9090:9090 -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
```

---

## Part 5: Nginx Configuration

### Create nginx.conf

```nginx
# nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/s;

    # Upstream API server
    upstream api_backend {
        server api:5000;
    }

    # HTTP redirect to HTTPS
    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name api.yourcompany.com;

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        # API endpoints
        location /api/ {
            limit_req zone=api_limit burst=200 nodelay;
            
            proxy_pass http://api_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # Static files
        location /static/ {
            alias /usr/share/nginx/html/static/;
            expires 30d;
        }

        # Health check
        location /health {
            proxy_pass http://api_backend;
        }

        # Deny access to sensitive files
        location ~ /\. {
            deny all;
        }
    }
}
```

---

## Part 6: Monitoring & Alerts

### Create monitoring.py

```python
# monitoring.py
import logging
from prometheus_client import Counter, Histogram, Gauge, generate_latest
from datetime import datetime
import time

# Metrics
request_count = Counter(
    'api_requests_total',
    'Total API requests',
    ['method', 'endpoint', 'status']
)

request_duration = Histogram(
    'api_request_duration_seconds',
    'API request duration',
    ['endpoint']
)

db_connections = Gauge(
    'db_connections_active',
    'Active database connections'
)

riders_total = Gauge(
    'riders_total',
    'Total riders'
)

quests_active = Gauge(
    'quests_active',
    'Active quests'
)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)
```

### Create alerting.py

```python
# alerting.py
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

class AlertManager:
    def __init__(self, smtp_server, smtp_port, email, password):
        self.smtp_server = smtp_server
        self.smtp_port = smtp_port
        self.email = email
        self.password = password

    def send_alert(self, subject, message, recipients):
        """Send alert email"""
        msg = MIMEMultipart()
        msg['From'] = self.email
        msg['To'] = ', '.join(recipients)
        msg['Subject'] = f"⚠️ ALERT: {subject}"

        msg.attach(MIMEText(message, 'plain'))

        try:
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.email, self.password)
                server.send_message(msg)
            return True
        except Exception as e:
            print(f"Alert send failed: {e}")
            return False

    def alert_high_error_rate(self, error_rate):
        """Alert on high error rate"""
        if error_rate > 0.05:  # 5% error rate threshold
            self.send_alert(
                "High API Error Rate",
                f"Error rate reached {error_rate*100}%",
                ["ops@yourcompany.com"]
            )

    def alert_db_down(self):
        """Alert on database down"""
        self.send_alert(
            "Database Connection Lost",
            "Unable to connect to production database",
            ["ops@yourcompany.com", "dba@yourcompany.com"]
        )

    def alert_low_disk_space(self, usage_percent):
        """Alert on low disk space"""
        if usage_percent > 90:
            self.send_alert(
                "Low Disk Space Warning",
                f"Disk usage at {usage_percent}%",
                ["ops@yourcompany.com"]
            )
```

---

## Part 7: Health Checks

### Create health_check.py

```python
# health_check.py
from database import get_connection
import logging

logger = logging.getLogger(__name__)

class HealthCheck:
    @staticmethod
    def database():
        """Check database connection"""
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            conn.close()
            return {"status": "healthy", "component": "database"}
        except Exception as e:
            logger.error(f"Database health check failed: {e}")
            return {"status": "unhealthy", "component": "database", "error": str(e)}

    @staticmethod
    def api():
        """Check API server"""
        return {"status": "healthy", "component": "api"}

    @staticmethod
    def all_checks():
        """Run all health checks"""
        checks = {
            "database": HealthCheck.database(),
            "api": HealthCheck.api()
        }
        
        all_healthy = all(check["status"] == "healthy" for check in checks.values())
        
        return {
            "status": "healthy" if all_healthy else "degraded",
            "checks": checks,
            "timestamp": datetime.utcnow().isoformat()
        }
```

---

## Part 8: Backup Schedule

### Create cron jobs

```bash
# Setup daily backups at 2 AM
crontab -e

# Add these lines:
0 2 * * * /path/to/backup_db.sh >> /var/log/backup.log 2>&1

# Weekly backup at 3 AM Sunday
0 3 * * 0 /path/to/backup_db.sh >> /var/log/backup.log 2>&1

# Daily health check at 8 AM
0 8 * * * curl -f http://localhost/health || echo "Health check failed" | mail -s "Alert" ops@company.com
```

---

## Part 9: Production Checklist

- [ ] Database backed up
- [ ] SSL certificates installed
- [ ] Environment variables configured
- [ ] Docker containers built and tested
- [ ] Health checks passing
- [ ] Monitoring configured
- [ ] Logging configured
- [ ] Backup schedule created
- [ ] Disaster recovery plan documented
- [ ] Team notified of deployment

---

## Part 10: Rollback Procedure

If issues occur after deployment:

```bash
# 1. Check current status
docker-compose ps
docker-compose logs api

# 2. Identify issue
curl http://localhost:5000/health

# 3. Rollback previous version
docker-compose down
git checkout previous-version
docker-compose build
docker-compose up -d

# 4. Restore database if needed
bash restore_db.sh /backups/rider_incentive/backup_YYYYMMDD_HHMMSS.sql.gz

# 5. Verify restoration
curl http://localhost:5000/health
```

---

## Troubleshooting

### MySQL won't start
```bash
# Check logs
docker logs rider_incentive_db

# Verify disk space
df -h

# Check permissions
ls -la /var/lib/docker/volumes/
```

### API connection failures
```bash
# Test database connection
docker exec rider_incentive_api python -c "from database import get_connection; print(get_connection())"

# Check network
docker network inspect incentive_network

# Restart services
docker-compose restart api
```

### High latency
```bash
# Check resource usage
docker stats

# Optimize MySQL
docker exec rider_incentive_db mysql -uroot -p -e "SHOW VARIABLES LIKE 'max_connections';"

# Scale up if needed
# Update docker-compose.yml with more resources
```

---

## Success Indicators

✅ All containers running and healthy
✅ Database queries executing < 100ms
✅ API responding < 200ms
✅ Error rate < 0.1%
✅ Health checks passing
✅ Logs clean and informative
✅ Backups completing successfully
✅ Monitoring data flowing

---

*Deployment Guide v1.0*
*Last Updated: 2026-09-17*
