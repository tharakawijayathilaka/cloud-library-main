# Cloud Library Management System — Complete Project Guide

## ITS 2130 - Enterprise Cloud Architecture Final Project

This document walks you through **every step** of building and deploying this project, from understanding the requirements to final submission.

---

# PHASE 1 — Requirement Breakdown

Here is every mandatory requirement from the guideline and how this project meets it:

| # | Requirement | How We Meet It |
|---|-------------|----------------|
| 1 | 2–5 microservices (3 recommended) | 3 services: Member, Book, Borrowing |
| 2 | Java 25 + Spring Boot + Spring Cloud + Spring Data | All pom.xml files use Java 25, Spring Boot 3.4.4, Spring Cloud 2024.0.1 |
| 3 | Config Server | `platform/config-server` on port 8888 |
| 4 | Eureka Service Registry | `platform/eureka-server` on port 8761 |
| 5 | API Gateway | `platform/api-gateway` on port 8080 |
| 6 | One service with Relational DB (MySQL/PostgreSQL) | Member Service → PostgreSQL via Cloud SQL |
| 7 | One service with Non-Relational DB (MongoDB) | Book Service + Borrowing Service → MongoDB |
| 8 | Google Cloud Storage bucket | Book Service stores cover images in GCS bucket |
| 9 | Frontend consuming all APIs through Gateway | `frontend/index.html` — Members, Books, Borrowings tabs |
| 10 | Polyrepo + Git submodules | Parent repo + 3 submodule repos |
| 11 | PM2 with auto-restart | `pm2/ecosystem.config.js` — autorestart: true, pm2 startup |
| 12 | High Availability (multi-zone) | MIGs with 2+ instances across zones |
| 13 | Auto Scaling | MIGs with autoscaling (CPU 60%) |
| 14 | VM Instance Groups, Templates, Images | Golden VM → Disk Image → Instance Template → MIG |
| 15 | Health Checks | Spring Actuator `/actuator/health` on every service |
| 16 | Cloud DNS | DNS zone pointing to Load Balancer IP |
| 17 | Load Balancer | HTTP(S) LB in front of API Gateway MIG |
| 18 | Cloud NAT + Cloud Router | NAT for outbound internet from private VMs |
| 19 | Cloud SQL | PostgreSQL instance for Member Service |
| 20 | Firestore | MongoDB on VM (or Firestore if preferred) |
| 21 | Cloud Storage Buckets | Bucket for book cover images |
| 22 | VPC + Firewall Rules | Custom VPC with allow-internal, allow-health-check, etc. |
| 23 | Eureka Dashboard URL in README | Placeholder in README.md — fill before submission |
| 24 | Screen recording | Checklist provided in docs/gcp-deploy.md |

---

# PHASE 2 — Project Idea

**Cloud Library Management System** — A simple library where members can borrow books.

Why this idea works:
- Simple enough to build quickly (3 basic CRUD services)
- Naturally requires both relational DB (members have structured data) and MongoDB (books/borrowings are document-like)
- Cover image upload gives a natural reason for Cloud Storage
- Completely different from the sample Juice Bar POS project
- All three services are clearly distinct and interact with each other (borrowings reference both members and books)

The three services:
1. **Member Service** — CRUD for library members (name, email, phone, address). Uses PostgreSQL.
2. **Book Service** — CRUD for books + cover image upload to GCS. Uses MongoDB.
3. **Borrowing Service** — Borrow/return books. Tracks who borrowed what. Uses MongoDB.

---

# PHASE 3 — Architecture

```
                    ┌───────────────────────┐
                    │   Frontend (HTML/JS)   │
                    │   frontend/index.html  │
                    └───────────┬───────────┘
                                │ HTTP
                    ┌───────────▼───────────┐
                    │   Load Balancer (GCP)  │
                    └───────────┬───────────┘
                                │
                    ┌───────────▼───────────┐
                    │  API Gateway (:8080)   │◄──── Eureka (:8761)
                    │  Routes all requests   │           │
                    └───┬───────┬───────┬───┘    Config Server (:8888)
                        │       │       │               │
               ┌────────▼┐ ┌───▼────┐ ┌▼─────────┐    │
               │ Member   │ │ Book   │ │ Borrowing │    │
               │ :8081    │ │ :8082  │ │ :8083     │◄───┘
               └────┬─────┘ └──┬──┬──┘ └────┬─────┘
                    │          │  │          │
               ┌────▼─────┐ ┌─▼──▼──┐ ┌────▼─────┐
               │Cloud SQL  │ │MongoDB│ │ MongoDB  │
               │PostgreSQL │ │+ GCS  │ │          │
               └──────────┘ │Bucket │ └──────────┘
                            └───────┘
```

### Port Map

| Service | Port | What It Does |
|---------|------|-------------|
| Config Server | 8888 | Serves YAML configs to all services |
| Eureka Server | 8761 | Service registry + dashboard |
| API Gateway | 8080 | Routes /members/**, /books/**, /borrowings/** |
| Member Service | 8081 | Member CRUD → PostgreSQL |
| Book Service | 8082 | Book CRUD + image upload → MongoDB + GCS |
| Borrowing Service | 8083 | Borrow/return → MongoDB |

### How Requests Flow

1. User opens frontend → clicks "Add Member"
2. Frontend sends `POST /members` to `GATEWAY_URL` (Load Balancer IP)
3. Load Balancer forwards to one of the API Gateway instances
4. Gateway looks up `MEMBER-SERVICE` in Eureka → finds available instances
5. Gateway routes request to a Member Service instance
6. Member Service saves to Cloud SQL PostgreSQL
7. Response flows back: Member Service → Gateway → Load Balancer → Frontend

---

# PHASE 4 — Repository Structure with Git Submodules

### What You Need to Create on GitHub

You need **4 public GitHub repositories**:

| Repository Name | Contains |
|----------------|----------|
| `Cloud-Library-System` | Parent repo (main submission) |
| `cloud-library-platform` | config-server, eureka-server, api-gateway |
| `cloud-library-services` | member-service, book-service, borrowing-service |
| `cloud-library-frontend` | index.html, css/, js/ |

### Step-by-Step: Setting Up Git Submodules

```bash
# ============================================================
# Step 1: Create the 3 child repos on GitHub first
# Go to github.com → New Repository for each:
#   - cloud-library-platform (public)
#   - cloud-library-services (public)
#   - cloud-library-frontend (public)
# ============================================================

# Step 2: Push the platform code
cd /path/to/project/platform
git init
git add .
git commit -m "Initial commit: Config Server, Eureka, API Gateway"
git remote add origin https://github.com/YOUR_USERNAME/cloud-library-platform.git
git branch -M main
git push -u origin main

# Step 3: Push the services code
cd /path/to/project/services
git init
git add .
git commit -m "Initial commit: Member, Book, Borrowing services"
git remote add origin https://github.com/YOUR_USERNAME/cloud-library-services.git
git branch -M main
git push -u origin main

# Step 4: Push the frontend code
cd /path/to/project/frontend
git init
git add .
git commit -m "Initial commit: Frontend application"
git remote add origin https://github.com/YOUR_USERNAME/cloud-library-frontend.git
git branch -M main
git push -u origin main

# ============================================================
# Step 5: Create the PARENT repository
# Go to github.com → New Repository: Cloud-Library-System (public)
# ============================================================

# Step 6: Set up parent with submodules
mkdir Cloud-Library-System
cd Cloud-Library-System
git init

# Add submodules (this links the child repos)
git submodule add https://github.com/YOUR_USERNAME/cloud-library-platform.git platform
git submodule add https://github.com/YOUR_USERNAME/cloud-library-services.git services
git submodule add https://github.com/YOUR_USERNAME/cloud-library-frontend.git frontend

# Copy remaining files into parent repo
# (copy config-repo/, pm2/, scripts/, docs/, pom.xml, README.md, .gitignore)

git add .
git commit -m "Initial commit: Parent repo with submodules"
git remote add origin https://github.com/YOUR_USERNAME/Cloud-Library-System.git
git branch -M main
git push -u origin main
```

### Verification

After pushing, go to your parent repo on GitHub. You should see:
- `platform` folder with a link icon (→ submodule)
- `services` folder with a link icon (→ submodule)
- `frontend` folder with a link icon (→ submodule)

Clicking each should navigate to the respective repository. **Test this in Incognito mode!**

---

# PHASE 5 — Backend Code Summary

All code is in the project zip. Here is what each file does:

### Platform Services

**Config Server** (`platform/config-server/`)
- `ConfigServerApplication.java` — Main class with `@EnableConfigServer`
- `application.yml` — Port 8888, native profile, reads from `config-repo/`

**Eureka Server** (`platform/eureka-server/`)
- `EurekaServerApplication.java` — Main class with `@EnableEurekaServer`
- `application.yml` — Port 8761, self-registration disabled

**API Gateway** (`platform/api-gateway/`)
- `ApiGatewayApplication.java` — Main class with `@EnableDiscoveryClient`
- `CorsConfig.java` — Allows frontend to call the gateway (CORS)
- `application.yml` — Port 8080, routes `/members/**`, `/books/**`, `/borrowings/**`

### Microservices

**Member Service** (`services/member-service/`) — PostgreSQL
- `Member.java` — JPA entity with `@Entity` + `@Table("members")`
- `MemberRepository.java` — `JpaRepository<Member, Long>`
- `MemberDTO.java` — Data transfer object
- `MemberService.java` — Business logic (CRUD)
- `MemberController.java` — REST endpoints: GET/POST/PUT/DELETE `/members`

**Book Service** (`services/book-service/`) — MongoDB + GCS
- `Book.java` — MongoDB document with `@Document("books")`
- `BookRepository.java` — `MongoRepository<Book, String>`
- `BookDTO.java` — Data transfer object
- `CloudStorageService.java` — Uploads images to GCS bucket, falls back to local
- `BookService.java` — Business logic (CRUD + cover upload)
- `BookController.java` — REST endpoints including `POST /books/{id}/cover`

**Borrowing Service** (`services/borrowing-service/`) — MongoDB
- `Borrowing.java` — MongoDB document with `@Document("borrowings")`
- `BorrowingRepository.java` — `MongoRepository<Borrowing, String>`
- `BorrowingDTO.java` — Data transfer object
- `BorrowingService.java` — Business logic (borrow/return)
- `BorrowingController.java` — REST endpoints including `PUT /borrowings/{id}/return`

---

# PHASE 6 — Frontend Code Summary

The frontend is a **single-page HTML application** with three tabs:

1. **Members Tab** — Form to add/edit members, list of all members with edit/delete buttons
2. **Books Tab** — Form to add/edit books, cover image upload, list with thumbnails
3. **Borrowings Tab** — Dropdowns to select member + book, borrow button, return button

**Key file:** `frontend/js/api.js`
- Line 8: `const GATEWAY_URL = 'http://localhost:8080';`
- **You MUST change this** to your Load Balancer IP for GCP deployment

All API calls go through the Gateway:
- `GET  GATEWAY_URL/members` → Member Service
- `POST GATEWAY_URL/books` → Book Service
- `POST GATEWAY_URL/books/{id}/cover` → Book Service (GCS upload)
- `POST GATEWAY_URL/borrowings` → Borrowing Service

This proves all three microservices are working through the API Gateway.

---

# PHASE 7 — GCP Deployment Steps (Summary)

Full detailed guide: `docs/gcp-deploy.md`

Here is the condensed order of operations:

1. **Create GCP project** → note Project ID
2. **Create VPC** + subnet + firewall rules (allow-internal, allow-health-check, allow-gateway, allow-eureka, allow-ssh)
3. **Create Cloud NAT** + Cloud Router (for outbound internet)
4. **Create Cloud SQL** PostgreSQL instance → create `cloud_library_members` database
5. **Create MongoDB VM** → install MongoDB, bind to 0.0.0.0
6. **Create Cloud Storage bucket** → create service account with Storage Object Admin role → download JSON key
7. **Build all JARs** locally: `./scripts/build-all.sh`
8. **Create golden VM** → install JDK 25, Node.js, PM2 → upload project + JARs → configure env vars → start PM2 → verify
9. **Stop golden VM → Create disk image** from it
10. **Create instance templates** using the disk image
11. **Create MIGs** (one per service, 2+ instances, multi-zone, autoscaling)
12. **Create health checks** (one per service port)
13. **Create HTTP(S) Load Balancer** in front of Gateway MIG
14. **Create Cloud DNS zone** pointing to LB IP
15. **Update frontend** `GATEWAY_URL` to LB IP
16. **Expose Eureka dashboard** URL → add to README

---

# PHASE 8 — PM2 Setup

PM2 is a Node.js process manager that keeps your Java JARs running.

### Why PM2?
- Auto-restarts your services if they crash
- Starts services on VM boot
- Shows nice monitoring with `pm2 monit`
- The assignment requires it (no containers)

### On the VM:

```bash
# 1. Install PM2
npm install -g pm2

# 2. Navigate to your project
cd /opt/app

# 3. Start all services
pm2 start pm2/ecosystem.config.js

# 4. Save the process list (so PM2 remembers on reboot)
pm2 save

# 5. Set PM2 to start on boot
pm2 startup
# IMPORTANT: Copy and run the command PM2 outputs! It looks like:
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu

# 6. Verify all services are running
pm2 monit
# You should see 6 services: config-server, eureka-server, api-gateway,
# member-service, book-service, borrowing-service

# 7. Check logs if something fails
pm2 logs config-server
pm2 logs member-service
```

### Key PM2 Commands

| Command | What It Does |
|---------|-------------|
| `pm2 start ecosystem.config.js` | Start all services |
| `pm2 monit` | Interactive dashboard (show in screen recording!) |
| `pm2 list` | List all processes |
| `pm2 logs <name>` | View logs for a service |
| `pm2 restart <name>` | Restart a service |
| `pm2 save` | Save current process list |
| `pm2 startup` | Configure auto-start on boot |
| `pm2 resurrect` | Restore saved processes (used in startup script) |

### Testing Auto-Restart

```bash
# Kill a service to test auto-restart
pm2 stop member-service
# Wait 5 seconds...
pm2 list
# member-service should be restarting automatically!
```

---

# PHASE 9 — README Files

### Parent Repository README
The main `README.md` is already created with:
- Eureka Dashboard URL placeholder (FILL THIS IN before submission)
- Architecture diagram
- API endpoints
- Quick start instructions
- GCP deployment reference

### Before Submission Checklist for README
1. Replace `YOUR_EUREKA_PUBLIC_IP` with actual Eureka IP
2. Replace `YOUR_LOAD_BALANCER_IP` with actual LB IP
3. Replace `YOUR_GCP_PROJECT_ID` with actual project ID

### Submodule READMEs (Optional but Recommended)
You can add a simple README to each submodule repo:

**cloud-library-platform/README.md:**
```
# Cloud Library - Platform Services
Config Server (8888), Eureka Server (8761), API Gateway (8080)
Part of Cloud Library Management System.
```

**cloud-library-services/README.md:**
```
# Cloud Library - Microservices
Member Service (8081), Book Service (8082), Borrowing Service (8083)
Part of Cloud Library Management System.
```

**cloud-library-frontend/README.md:**
```
# Cloud Library - Frontend
Simple HTML/JS frontend that consumes all backend services through API Gateway.
Part of Cloud Library Management System.
```

---

# PHASE 10 — Final Submission Checklist

### Code Checklist
- [ ] All 6 Spring Boot services compile and build without errors
- [ ] Frontend consumes all 3 services through the API Gateway
- [ ] Member Service uses PostgreSQL (relational DB)
- [ ] Book Service uses MongoDB (NoSQL) + GCS (Cloud Storage)
- [ ] Borrowing Service uses MongoDB (NoSQL)
- [ ] Config Server centralizes configuration
- [ ] Eureka Server shows all services registered
- [ ] API Gateway routes to all services

### GitHub Checklist
- [ ] Parent repo is PUBLIC
- [ ] All 3 submodule repos are PUBLIC
- [ ] Can navigate from parent → each submodule
- [ ] Tested all links in **Incognito/Private** mode
- [ ] README.md has Eureka Dashboard URL
- [ ] README.md has GCP Project ID

### GCP Checklist
- [ ] VPC Network + subnets created
- [ ] Firewall rules configured
- [ ] Cloud Router + Cloud NAT created
- [ ] Cloud SQL PostgreSQL instance running
- [ ] MongoDB running on VM
- [ ] Cloud Storage bucket created with book covers
- [ ] VM Instance Templates created
- [ ] Managed Instance Groups (MIGs) created (min 2 instances each)
- [ ] MIGs are multi-zone (HA requirement!)
- [ ] Autoscaling enabled on MIGs
- [ ] Health checks configured for each service
- [ ] HTTP(S) Load Balancer in front of Gateway
- [ ] Cloud DNS configured
- [ ] Eureka Dashboard accessible publicly

### PM2 Checklist
- [ ] PM2 manages all 6 services
- [ ] `pm2 monit` shows all services running
- [ ] `pm2 startup` configured (auto-start on boot)
- [ ] `pm2 save` run (process list saved)
- [ ] Auto-restart works (kill a service → it comes back)

### Screen Recording Checklist
- [ ] Show GCP Console: VM Instance Groups
- [ ] Show GCP Console: VMs (all running instances)
- [ ] Show GCP Console: Instance Templates
- [ ] Show GCP Console: Disk Images
- [ ] Show GCP Console: Health Checks
- [ ] Show GCP Console: Cloud DNS
- [ ] Show GCP Console: Load Balancer
- [ ] Show GCP Console: Cloud NAT + Cloud Router
- [ ] Show GCP Console: Cloud SQL (show database)
- [ ] Show GCP Console: Cloud Storage (show bucket + files)
- [ ] Show GCP Console: VPC Network
- [ ] Show GCP Console: Firewall Rules
- [ ] SSH into each VM → run `pm2 monit` → show processes
- [ ] All IP addresses match your project configuration
- [ ] No audio needed (just screen recording)
- [ ] Upload to Google Drive (publicly accessible)
- [ ] Test video link in Incognito mode

### Submission Form Fields
1. **Google Cloud Platform Project ID** → your project ID
2. **Back-end: Microservices Platform Repository URL** → parent repo URL
3. **Back-end: Services Repository URL** → services submodule repo URL
4. **Front-end: Web Application Repository URL** → frontend submodule repo URL
5. **Screen Recording URL** → Google Drive link

---

**You now have everything you need. Good luck with your submission!**
