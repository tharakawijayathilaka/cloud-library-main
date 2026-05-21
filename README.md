# Cloud Library Management System

**ITS 2130 - Enterprise Cloud Architecture Final Project**

A cloud-native microservice-based Library Management System built with Spring Boot, Spring Cloud, and deployed on Google Cloud Platform.

---

## Live URLs

| Resource | URL |
|----------|-----|
| **Eureka Dashboard** | `http://YOUR_EUREKA_PUBLIC_IP:9001` |
| **API Gateway (LB)** | `http://YOUR_LOAD_BALANCER_IP` |
| **Frontend** | Open `frontend/index.html` pointing to the Gateway |

> **Important:** Replace the placeholder URLs above with your actual deployed URLs before submission.

---

## Architecture

```
[Frontend (HTML/JS)]
        |
[API Gateway :8080]  <-->  [Service Registry :9001]  <-->  [Config Server :9000]
        |                                              |
   +---------+-----------+          [Git: Cafeteria-System-Configurations]
                                  [Local: platform/config-server/.../configurations/]
   |         |           |
[Member   [Book       [Borrowing
 :8081]    :8082]       :8083]
   |         |           |
[Cloud    [MongoDB +   [MongoDB]
 SQL]      GCS Bucket]
```

## Microservices

| Service | Port | Database | Description |
|---------|------|----------|-------------|
| **Member Service** | 8081 | PostgreSQL (Cloud SQL) | CRUD for library members |
| **Book Service** | 8082 | MongoDB + GCS | CRUD for books + cover image upload to Cloud Storage |
| **Borrowing Service** | 8083 | MongoDB | Borrow/return books, tracks borrowing records |

## Platform Services

| Service | Port | Description |
|---------|------|-------------|
| **Config Server** | 9000 | Centralized configuration (Git + native profile for local dev) |
| **Service Registry** | 9001 | Eureka service discovery |
| **API Gateway** | 8080 | Single entry point, routes to all microservices |

## Technology Stack

- **Language:** Java 25
- **Framework:** Spring Boot 4.0.3
- **Cloud:** Spring Cloud 2025.1.0
- **Databases:** PostgreSQL (relational) + MongoDB (NoSQL)
- **Storage:** Google Cloud Storage (book cover images)
- **Deployment:** GCP Compute Engine VMs + PM2
- **Frontend:** HTML / CSS / JavaScript (vanilla)

## GCP Infrastructure Used

- VM Instance Groups (Managed)
- VM Instance Templates
- Disk Images
- Health Checks
- Cloud DNS
- HTTP(S) Load Balancer
- Cloud NAT Gateway
- Cloud SQL (PostgreSQL)
- MongoDB (on Compute Engine VM)
- Cloud Storage Buckets
- Cloud Router
- VPC Network
- Firewall Rules

## Repository Structure

This is a **polyrepo** project using **Git submodules**:

```
cloud-library-main/            ← Parent repository (multi-module Maven)
├── pom.xml                    ← Aggregates platform + services
├── ecosystem.config.js        ← PM2: full stack
├── platform/
│   ├── pom.xml
│   ├── ecosystem.config.js
│   ├── config-server/         ← Git + native configurations/
│   ├── service-registry/
│   └── api-gateway/
├── services/
│   ├── pom.xml
│   ├── ecosystem.config.js
│   ├── member-service/
│   ├── book-service/
│   └── borrowing-service/
├── frontend/
├── config-repo/               ← Legacy; see configurations/ in config-server
├── scripts/
└── docs/
```

## Quick Start (Local Development)

### Prerequisites
- JDK 25
- Maven 4.0+
- PostgreSQL running on localhost:5432
- MongoDB running on localhost:27017

### 1. Create PostgreSQL database
```sql
CREATE DATABASE cloud_library_members;
```

### 2. Build all services
```bash
chmod +x scripts/build-all.sh
./scripts/build-all.sh
```

### 3. Start services (in order)
```bash
chmod +x scripts/run-local.sh
./scripts/run-local.sh
```

### 4. Verify
- Eureka Dashboard: http://localhost:9001
- API Gateway: http://localhost:8080
- Test: `curl http://localhost:8080/members`

### 5. Open Frontend
Open `frontend/index.html` in your browser.

## API Endpoints (through Gateway on port 8080)

### Members
- `GET    /members` — List all members
- `GET    /members/{id}` — Get member by ID
- `POST   /members` — Create member
- `PUT    /members/{id}` — Update member
- `DELETE /members/{id}` — Delete member

### Books
- `GET    /books` — List all books
- `GET    /books/{id}` — Get book by ID
- `POST   /books` — Create book
- `PUT    /books/{id}` — Update book
- `DELETE /books/{id}` — Delete book
- `POST   /books/{id}/cover` — Upload cover image (multipart/form-data)
- `GET    /books/search?query=xyz` — Search books by title

### Borrowings
- `GET    /borrowings` — List all borrowings
- `GET    /borrowings/{id}` — Get borrowing by ID
- `GET    /borrowings/member/{memberId}` — Get borrowings by member
- `POST   /borrowings` — Borrow a book
- `PUT    /borrowings/{id}/return` — Return a book
- `DELETE /borrowings/{id}` — Delete borrowing record

## GCP Deployment

See full deployment guide: [docs/gcp-deploy.md](docs/gcp-deploy.md)

## PM2 Process Management

All services are managed by PM2 with automatic restart on failure:
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
pm2 monit
```

## Screen Recording Checklist

Your screen recording must show:
1. All GCP Console resources (MIGs, templates, images, health checks, DNS, LB, NAT, SQL, Storage, Router, VPC, Firewall)
2. SSH into each VM and run `pm2 monit` to show running processes
3. All IPs in GCP must match your project configuration

## Google Cloud Platform Project ID

```
YOUR_GCP_PROJECT_ID
```

---

*Cloud Library Management System — ITS 2130 Enterprise Cloud Architecture*
