# CodeSync-AI

📚 **Distributed Code Review System**

## 🎯 Project Overview

A real-time collaborative code review platform that combines human reviewers with AI-powered analysis, featuring live commenting, automated security scanning, and intelligent suggestions.

## 🏗️ Architecture

<div align="center">
  <img  width="1000" alt="codesync-screenshot" src="./docs/images/system-design.png">
</div>

## 🔧 Technical Stack

**Backend Services**

- Go 1.22+ with Gin (API Gateway)
- Python 3.11+ with FastAPI (AI Analysis Service)
- PostgreSQL 15
- Redis
- Docker & Docker Compose

**Frontend**

- React 18+ (TypeScript)
- Monaco Editor
- WebSocket
- Tailwind CSS

**DevOps & Monitoring**

- GitHub Actions (CI/CD)
- Nginx reverse proxy
- Prometheus + Grafana
- Docker

## 🚀 How Reviewers Work

### Reviewer Assignment Flow

1. Code Author creates a review
2. Author invites reviewers by:
   - Email addresses (internal/external)
   - GitHub usernames
   - Team selection
3. System sends invitation emails with unique tokens
4. Reviewers click invite link and:
   - Create account (if new user)
   - Accept/decline invitation
5. Accepted reviewers get review access

### Reviewer Roles & Permissions

- **Primary Reviewer:** Can approve/reject, required for completion
- **Secondary Reviewer:** Optional feedback
- **Observer:** View-only, notifications
- **Author:** Responds to comments

## 🤖 AI Analysis Engine

### AI Analysis Features

- **Security Scanning:** Vulnerabilities, injection attacks, dependencies
- **Code Quality:** Complexity, maintainability, duplication
- **Performance:** Bottlenecks, memory leaks, algorithms
- **Style Consistency:** Coding standards enforcement
- **Smart Suggestions:** Context-aware improvements via LLMs

## 🐳 Docker Setup

**docker-compose.yml**

```yaml
version: '3.8'
services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:8080
    depends_on:
      - api-gateway

  api-gateway:
    build:
      context: ./go-backend
      dockerfile: Dockerfile
    ports:
    - "8080:8080"
    environment:
      - DATABASE_URL=postgres://user:password@postgres:5432/codereviews
      - REDIS_URL=redis://redis:6379
      - ANALYSIS_SERVICE_URL=http://analysis-service:8000
      - JWT_SECRET=your-jwt-secret
    depends_on:
      - postgres
      - redis
      - analysis-service

  analysis-service:
    build:
      context: ./python-backend
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgres://user:password@postgres:5432/codereviews
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis
    postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=codereviews
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  nginx:
    image: nginx:alpine
    ports:
    - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - frontend
      - api-gateway

  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana

volumes:
  postgres_data:
  redis_data:
  grafana_data:
```

## 🚀 Quick Start Guide

### Prerequisites

- Docker & Docker Compose
- Node.js 18+
- Go 1.22+
- Python 3.11+

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
```

### Initialize Database

```bash
docker-compose exec api-gateway ./migrate up
docker-compose exec api-gateway ./seed-demo-data
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

## 📊 Monitoring

**Metrics Available**

- Application: latency, errors, throughput
- Business: reviews, completion, engagement
- Infrastructure: DB connections, memory, response times

**Grafana Dashboards**

- Application Overview: [http://localhost:3001](http://localhost:3001)
- Review Analytics
- System Health
- User Activity

---

## ⚡ GitHub Actions CI/CD

**.github/workflows/deploy.yml**

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: |
          docker-compose -f docker-compose.test.yml up --abort-on-container-exit
 deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        run: |
          # Your deployment script here
```

## 🔒 Security Considerations

- JWT token expiration/refresh
- Rate limiting
- SQL injection prevention
- XSS protection
- CORS configuration
- Input validation/sanitization
- File upload security
- Secure WebSocket connections

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Add tests
4. Make & Commit changes
5. Push to branch
6. Open a Pull Request

## 🔮 New Feature Ideas

**Advanced AI Features**

- AI Code Generation
- Intelligent Merge Conflict Resolution
- Code Documentation Generator
- Refactoring Suggestions
- Test Case Generation

**Enhanced Collaboration**

- Voice Comments
- Code Annotation

**Analytics & Reporting**

- Review Analytics Dashboard
- Code Quality Trends
- Developer Performance
- Team Insights
- Custom Reporting

**Advanced Review Features**

- Template System
- Review Checklists
- Approval Workflows
- Review Scheduling
- Anonymous Reviews

**Security & Compliance**

- RBAC
- Audit Logging
- GDPR Compliance
- SSO Integration
- Compliance Reporting

**Advanced Code Analysis**

- License Compliance
- Dependency Vulnerability
- Performance Profiling
- Code Coverage
- Architecture Analysis

## 📞 Support

**Getting Help**

- Documentation: See README and inline docs
- Issues: GitHub issues for bugs/features
- Discussions: GitHub Discussions
- Email: support@example.com

## 🙏 Acknowledgments

Special thanks to all contributors, open-source maintainers, and the developer community for their support and inspiration. This project leverages many open-source tools and libraries—your work makes innovation possible!

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
 </div>
