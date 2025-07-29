# CodeSync-AI

📚 **Next-Generation Distributed Code Review Platform Powered By AI**

_Combining AI-powered analysis with real-time human collaboration_

## 🎯 Project Overview

CodeSync-AI revolutionizes code review workflows with:

- **🤖 AI-Powered Analysis:** Advanced security scanning, code quality assessment, and intelligent suggestions
- **⚡ Real-Time Collaboration:** Live commenting, WebSocket-powered interactions,Chat-based Feedback Interface, and instant notifications
- **🔒 Enterprise Security:** JWT authentication, rate limiting, and comprehensive audit logging
- **📊 Advanced Analytics:** Performance insights, review metrics, and team productivity tracking
  **🔗 Seamless Integrations:** GitHub, Slack, JIRA, and VS Code extension support

## 🏗️ Architecture

### System Design Overview

_Our microservices architecture leverages:_

- Kong API Gateway for traffic management and security
- Event-driven messaging with RabbitMQ
- Comprehensive observability with Prometheus, Grafana, and Jaeger
- Scalable data layer with PostgreSQL and Redis

<div align="center">
  <img  width="1000" alt="codesync-screenshot" src="./docs/images/system-design.png">
</div>

## 🔧 Technical Stack

**Backend Services**

- 🐹 Go 1.22+ - High-performance API services
- 🐍 Python 3.11+ - AI/ML analysis engine
- 🗄️ PostgreSQL 15 - Primary data store with advanced indexing
- 🔴 Redis 7 - Caching, sessions, and real-time data
- 🐰 RabbitMQ - Asynchronous message processing
- 🦍 Kong - API Gateway with enterprise plugins

**Frontend**

- ⚛️ React 18+ (TypeScript) - Modern web interface
- 📱 React Native - Mobile applications
- 🎨 Monaco Editor - Advanced code editing
- 🔌 VS Code Extension - IDE integration
- ⚡ WebSocket - Real-time communication

**DevOps & Infrastructure**

- 🐳 Docker & Compose - Containerization
- 📊 Prometheus + Grafana - Metrics and dashboards
- 📝 Loki - Centralized logging
- 🔍 Jaeger - Distributed tracing
- 🔍 Elasticsearch - Full-text search and code indexing
- 🚀 GitHub Actions - CI/CD pipeline

### 🤖 AI Analysis Features

- **Security Scanning:** Vulnerabilities, injection attacks, dependencies
- **Code Quality:** Complexity, maintainability, duplication
- **Performance:** Bottlenecks, memory leaks, algorithms
- **Style Consistency:** Coding standards enforcement
- **Smart Suggestions:** Context-aware improvements via LLMs

## 🐳 Docker Setup

**docker-compose.yml**

```yaml
version: "3.8"

networks:
  codesync-network:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
  rabbitmq_data:
  grafana_data:
  prometheus_data:
  loki_data:
  minio_data:

services:
  # === FRONTEND SERVICES ===
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        - NODE_ENV=production
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:8000
      - REACT_APP_WS_URL=ws://localhost:8000/ws
      - REACT_APP_VERSION=2.0.0
    depends_on:
      - kong
    networks:
      - codesync-network
    restart: unless-stopped

  # === API GATEWAY ===
  kong:
    image: kong:3.4
    ports:
      - "8000:8000" # Proxy
      - "8001:8001" # Admin API
      - "8443:8443" # SSL Proxy
      - "8444:8444" # SSL Admin
    environment:
      - KONG_DATABASE=postgres
      - KONG_PG_HOST=postgres
      - KONG_PG_DATABASE=kong_db
      - KONG_PG_USER=kong
      - KONG_PG_PASSWORD=kong_password
      - KONG_ADMIN_LISTEN=0.0.0.0:8001
      - KONG_PROXY_ACCESS_LOG=/dev/stdout
      - KONG_ADMIN_ACCESS_LOG=/dev/stdout
      - KONG_PROXY_ERROR_LOG=/dev/stderr
      - KONG_ADMIN_ERROR_LOG=/dev/stderr
      - KONG_LOG_LEVEL=info
      - KONG_PLUGINS=bundled,rate-limiting,jwt,cors,request-logging,response-logging
    depends_on:
      - postgres
      - redis
    networks:
      - codesync-network
    restart: unless-stopped
    volumes:
      - ./kong/kong.conf:/etc/kong/kong.conf

  # === APPLICATION SERVICES ===
  api-gateway:
    build:
      context: ./go-backend
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
      - DATABASE_URL=postgres://codesync:secure_password@postgres:5432/codesync_db?sslmode=disable
      - REDIS_URL=redis://redis:6379/0
      - RABBITMQ_URL=amqp://codesync:rabbitmq_pass@rabbitmq:5672/
      - JWT_SECRET=${JWT_SECRET}
      - AI_SERVICE_URL=http://ai-analysis:8000
      - WEBSOCKET_SERVICE_URL=http://websocket-service:8082
      - NOTIFICATION_SERVICE_URL=http://notification-service:8083
      - GITHUB_SERVICE_URL=http://github-service:8084
      - JAEGER_ENDPOINT=http://jaeger:14268/api/traces
      - PROMETHEUS_METRICS_PORT=9091
    depends_on:
      - postgres
      - redis
      - rabbitmq
    networks:
      - codesync-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  ai-analysis:
    build:
      context: ./python-backend
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgres://codesync:secure_password@postgres:5432/codesync_db
      - REDIS_URL=redis://redis:6379/1
      - RABBITMQ_URL=amqp://codesync:rabbitmq_pass@rabbitmq:5672/
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - HUGGINGFACE_API_KEY=${HUGGINGFACE_API_KEY}
      - MODEL_CACHE_DIR=/app/models
      - JAEGER_ENDPOINT=http://jaeger:14268/api/traces
      - PROMETHEUS_METRICS_PORT=9092
    depends_on:
      - postgres
      - redis
      - rabbitmq
    networks:
      - codesync-network
    restart: unless-stopped
    volumes:
      - ./ai-models:/app/models
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  websocket-service:
    build:
      context: ./websocket-service
      dockerfile: Dockerfile
    ports:
      - "8082:8082"
    environment:
      - PORT=8082
      - REDIS_URL=redis://redis:6379/2
      - RABBITMQ_URL=amqp://codesync:rabbitmq_pass@rabbitmq:5672/
      - JWT_SECRET=${JWT_SECRET}
      - CORS_ORIGINS=http://localhost:3000,https://codesync-ai.com
      - MAX_CONNECTIONS=10000
      - JAEGER_ENDPOINT=http://jaeger:14268/api/traces
    depends_on:
      - redis
      - rabbitmq
    networks:
      - codesync-network
    restart: unless-stopped

  notification-service:
    build:
      context: ./notification-service
      dockerfile: Dockerfile
    ports:
      - "8083:8083"
    environment:
      - PORT=8083
      - DATABASE_URL=postgres://codesync:secure_password@postgres:5432/codesync_db
      - RABBITMQ_URL=amqp://codesync:rabbitmq_pass@rabbitmq:5672/
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_PORT=${SMTP_PORT}
      - SMTP_USERNAME=${SMTP_USERNAME}
      - SMTP_PASSWORD=${SMTP_PASSWORD}
      - SLACK_BOT_TOKEN=${SLACK_BOT_TOKEN}
      - PUSH_NOTIFICATION_KEY=${PUSH_NOTIFICATION_KEY}
      - JAEGER_ENDPOINT=http://jaeger:14268/api/traces
    depends_on:
      - postgres
      - rabbitmq
    networks:
      - codesync-network
    restart: unless-stopped

  github-service:
    build:
      context: ./github-service
      dockerfile: Dockerfile
    ports:
      - "8084:8084"
    environment:
      - PORT=8084
      - DATABASE_URL=postgres://codesync:secure_password@postgres:5432/codesync_db
      - RABBITMQ_URL=amqp://codesync:rabbitmq_pass@rabbitmq:5672/
      - GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}
      - GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}
      - GITHUB_WEBHOOK_SECRET=${GITHUB_WEBHOOK_SECRET}
      - JAEGER_ENDPOINT=http://jaeger:14268/api/traces
    depends_on:
      - postgres
      - rabbitmq
    networks:
      - codesync-network
    restart: unless-stopped

  # === DATA LAYER ===
  postgres:
    image: postgres:15-alpine
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=codesync_db
      - POSTGRES_USER=codesync
      - POSTGRES_PASSWORD=secure_password
      - POSTGRES_MULTIPLE_DATABASES=kong_db:kong:kong_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/01-init.sql
      - ./database/kong-init.sql:/docker-entrypoint-initdb.d/02-kong-init.sql
      - ./database/migrations:/docker-entrypoint-initdb.d/migrations
    networks:
      - codesync-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U codesync -d codesync_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes --requirepass redis_password
    volumes:
      - redis_data:/data
      - ./redis/redis.conf:/etc/redis/redis.conf
    networks:
      - codesync-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  rabbitmq:
    image: rabbitmq:3.12-management-alpine
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      - RABBITMQ_DEFAULT_USER=codesync
      - RABBITMQ_DEFAULT_PASS=rabbitmq_pass
      - RABBITMQ_DEFAULT_VHOST=/
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
      - ./rabbitmq/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf
      - ./rabbitmq/definitions.json:/etc/rabbitmq/definitions.json
    networks:
      - codesync-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5

  # === FILE STORAGE ===
  minio:
    image: minio/minio:latest
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      - MINIO_ROOT_USER=codesync
      - MINIO_ROOT_PASSWORD=minio_secure_password
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data
    networks:
      - codesync-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

  # === SEARCH & INDEXING ===
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.10.0
    ports:
      - "9200:9200"
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - ./elasticsearch/data:/usr/share/elasticsearch/data
    networks:
      - codesync-network
    restart: unless-stopped

  # === MONITORING & OBSERVABILITY ===
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
      - "--web.console.libraries=/etc/prometheus/console_libraries"
      - "--web.console.templates=/etc/prometheus/consoles"
      - "--web.enable-lifecycle"
      - "--web.enable-admin-api"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./monitoring/rules:/etc/prometheus/rules
      - prometheus_data:/prometheus
    networks:
      - codesync-network
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards
    networks:
      - codesync-network
    restart: unless-stopped
    depends_on:
      - prometheus

  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - ./monitoring/loki/loki-config.yml:/etc/loki/local-config.yaml
      - loki_data:/loki
    networks:
      - codesync-network
    restart: unless-stopped

  promtail:
    image: grafana/promtail:latest
    volumes:
      - ./monitoring/promtail/promtail-config.yml:/etc/promtail/config.yml
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - codesync-network
    restart: unless-stopped
    depends_on:
      - loki

  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"
      - "14268:14268"
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    networks:
      - codesync-network
    restart: unless-stopped
```

## 🚀 Quick Start Guide

### Prerequisites

- Docker & Docker Compose v2.0+
- Node.js 18+ & npm
- Go 1.22+
- Python 3.11+
- Git

### Installation

```bash
git clone https://github.com/nickemma/CodeSync-AI.git
cd CodeSync-AI
```

### Environment Setup

```bash
cp .env.example .env
nano .env
```

### Start All Services

```bash
docker-compose up -d

docker-compose ps

docker-compose logs -f api-gateway
```

### Initialize Database

```bash
docker-compose exec api-gateway ./scripts/migrate.sh

docker-compose exec kong kong config init
./scripts/setup-kong-plugins.sh
```

### Access the Application

```bash
# Open your browser
http://localhost:3000
```

**Demo credentials:**  
Email: `demo@example.com`  
Password: `demopassword`

### Development Mode

```bash
docker-compose up -d postgres redis

# Go backend
cd go-backend
go mod download
go run main.go

# Python analysis service
cd python-backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000

# React frontend
cd frontend
npm install
npm start
```

## 🔧 Configuration

**Environment Variables (.env)**

```bash
DATABASE_URL=postgres://user:password@localhost:5432/codereviews
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-super-secret-jwt-key
OPENAI_API_KEY=your-openai-api-key

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# GitHub
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret

# Slack
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
```

---

## 🧪 Testing

**Run Tests**

```bash
# Go backend
cd go-backend
go test ./... -v

# Python analysis service
cd python-backend
pytest tests/ -v

# React frontend
cd frontend
npm test

# Integration tests
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

## 🔒 Security & Compliance

### Authentication & Authorization

- Multi-Factor Authentication (MFA) with TOTP/SMS
- Single Sign-On (SSO) with SAML/OAuth2
- Role-Based Access Control (RBAC) with fine-grained permissions
- JWT Token Management with refresh token rotation
- Session Management with Redis-backed storage

### Data Protection

- Encryption at Rest: AES-256 for sensitive data
- Encryption in Transit: TLS 1.3 for all communications
- API Security: Rate limiting, request validation, SQL injection prevention
- Audit Logging: Comprehensive activity tracking
- GDPR Compliance: Data privacy and user rights management

---

## Security Scanning

```bash
# Container Security Scanning
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image codesync/api-gateway:latest

# Dependency Vulnerability Scanning
docker run --rm -v $(pwd):/app \
  owasp/dependency-check --project CodeSync --scan /app

# Infrastructure Security
docker run --rm -v $(pwd):/tf bridgecrew/checkov -d /tf
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Add tests
4. Make & Commit changes
5. Push to branch
6. Open a Pull Request

## 🔮 New Feature Ideas

<!-- Coming Soon -->

## 📞 Support

**Getting Help**

- Documentation: See README and inline docs
- Issues: GitHub issues for bugs/features
- Discussions: GitHub Discussions
- Email: support@example.com

## 🙏 Acknowledgments

Special thanks to our amazing contributors and the open-source community:

- **Open Source Libraries:** React, Go, Python, Docker, and countless others
- **AI/ML Partners:** OpenAI, Hugging Face for providing excellent APIs
- **Infrastructure:** Kong, Prometheus, Grafana for robust tooling
- **Community:** All our beta users and feedback providers

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

Built with ❤️ for the developer community.

### 👤 Author

#### Nicholas Emmanuel

 <div align="center">
 <a href="https://www.linkedin.com/in/techieemma"><img src="https://img.shields.io/badge/linkedin-%23f78a38.svg?style=for-the-badge&logo=linkedin&logoColor=white" alt="Linkedin"></a> 
 <a href="https://twitter.com/techieEmma"><img src="https://img.shields.io/badge/Twitter-%23f78a38.svg?style=for-the-badge&logo=Twitter&logoColor=white" alt="Twitter"></a> 
 <a href="https://github.com/nickemma/"><img src="https://img.shields.io/badge/github-%23f78a38.svg?style=for-the-badge&logo=github&logoColor=white" alt="Github"></a> 
 <a href="https://techieemma.medium.com/"><img src="https://img.shields.io/badge/Medium-%23f78a38.svg?style=for-the-badge&logo=Medium&logoColor=white" alt="Medium"></a> 
 <a href="mailto:nicholasemmanuel321@gmail.com"><img src="https://img.shields.io/badge/Gmail-f78a38?style=for-the-badge&logo=gmail&logoColor=white" alt="Linkedin"></a>

## _⭐ Star this repo if you found it helpful!_

 </div>
