# GCP Deployment Guide - Cloud Library System

This is a step-by-step guide to deploy the Cloud Library system on Google Cloud Platform.
Follow these steps exactly as shown in your lectures.

---

## STEP 1: Create GCP Project

1. Go to https://console.cloud.google.com
2. Create a new project (e.g., `cloud-library-project`)
3. Note your **Project ID** (you need this for submission)
4. Enable these APIs:
   - Compute Engine API
   - Cloud SQL Admin API
   - Cloud Storage API
   - Cloud DNS API

---

## STEP 2: VPC Network + Firewall Rules

### Create VPC
1. Go to **VPC Network → VPC Networks → Create VPC Network**
2. Name: `cloud-library-vpc`
3. Add a subnet:
   - Name: `cloud-library-subnet`
   - Region: `asia-southeast1` (or your preferred region)
   - IP range: `10.0.0.0/24`
4. Click Create

### Firewall Rules
Go to **VPC Network → Firewall → Create Firewall Rule**

Create these rules:

| Name | Direction | Targets | Source | Ports | Purpose |
|------|-----------|---------|--------|-------|---------|
| allow-internal | Ingress | All instances | 10.0.0.0/24 | all | Internal communication |
| allow-health-check | Ingress | All instances | 130.211.0.0/22, 35.191.0.0/16 | tcp:8080,8761,8081,8082,8083 | GCP health checks |
| allow-gateway-external | Ingress | Tag: gateway | 0.0.0.0/0 | tcp:8080 | External access to Gateway |
| allow-eureka-external | Ingress | Tag: eureka | 0.0.0.0/0 | tcp:8761 | Eureka Dashboard access |
| allow-ssh | Ingress | All instances | 0.0.0.0/0 | tcp:22 | SSH access |

---

## STEP 3: Cloud NAT + Cloud Router

This lets your private VMs access the internet (for downloading packages).

1. Go to **Network Services → Cloud NAT → Create**
2. Name: `cloud-library-nat`
3. Select your VPC network and region
4. Create a new Cloud Router:
   - Name: `cloud-library-router`
   - Region: same as subnet
5. NAT mapping: All subnets
6. Click Create

---

## STEP 4: Cloud SQL (PostgreSQL) for Member Service

1. Go to **SQL → Create Instance → PostgreSQL**
2. Instance ID: `cloud-library-sql`
3. Password: set a strong password (note it down!)
4. Database version: PostgreSQL 15
5. Region: same as your VPC
6. Connectivity: **Private IP** (select your VPC)
7. Click Create (takes ~5 minutes)

After creation:
1. Click on the instance → **Databases** → Create database: `cloud_library_members`
2. Note the **Private IP** (e.g., `10.0.0.5`) — used in env vars

---

## STEP 5: MongoDB VM (for Book + Borrowing services)

1. Go to **Compute Engine → VM Instances → Create**
2. Name: `mongodb-vm`
3. Region/Zone: same region as your VPC
4. Machine type: `e2-small`
5. Boot disk: Ubuntu 22.04, 20GB
6. Networking: your VPC, subnet
7. Create the VM, then SSH into it:

```bash
# Install MongoDB
sudo apt-get update
sudo apt-get install -y gnupg curl
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org

# Configure to listen on all interfaces
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

# Start MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod
```

Note the **Internal IP** of this VM (e.g., `10.0.0.3`)

---

## STEP 6: Cloud Storage Bucket (for book cover images)

1. Go to **Cloud Storage → Create Bucket**
2. Name: `cloud-library-covers-UNIQUE_SUFFIX` (must be globally unique)
3. Region: same region
4. Storage class: Standard
5. Access control: Uniform
6. Click Create

### Create Service Account for Storage Access
1. Go to **IAM & Admin → Service Accounts → Create**
2. Name: `cloud-library-storage`
3. Grant role: **Storage Object Admin**
4. Create a JSON key → download it
5. Upload the key to your VM at `/opt/app/keys/service-account.json`

---

## STEP 7: Build JARs on Your Local Machine

```bash
# Make sure you have JDK 25 and Maven 4.0+ installed
chmod +x scripts/build-all.sh
./scripts/build-all.sh
```

This creates JAR files:
- `platform/config-server/target/config-server-1.0.0.jar`
- `platform/eureka-server/target/eureka-server-1.0.0.jar`
- `platform/api-gateway/target/api-gateway-1.0.0.jar`
- `services/member-service/target/member-service-1.0.0.jar`
- `services/book-service/target/book-service-1.0.0.jar`
- `services/borrowing-service/target/borrowing-service-1.0.0.jar`

---

## STEP 8: Create Golden VM Image

### Create a base VM first:
1. Go to **Compute Engine → VM Instances → Create**
2. Name: `golden-vm`
3. Machine type: `e2-medium`
4. Boot disk: Ubuntu 22.04, 30GB
5. Network: your VPC

### SSH into golden-vm and set up:
```bash
# Install JDK 25
sudo apt-get update
sudo apt-get install -y wget
wget https://download.oracle.com/java/25/latest/jdk-25_linux-x64_bin.deb
sudo dpkg -i jdk-25_linux-x64_bin.deb
java -version

# Install Node.js + PM2
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2

# Create app directory
sudo mkdir -p /opt/app/logs /opt/app/keys
sudo chown -R $USER:$USER /opt/app
```

### Upload your project to the VM:
```bash
# From your local machine, use SCP or gcloud:
gcloud compute scp --recurse ./project/* golden-vm:/opt/app/ --zone=YOUR_ZONE
```

### Set up environment variables on the VM:
```bash
# Copy and edit the env template
cp /opt/app/docs/env-template.sh /opt/app/env.sh
nano /opt/app/env.sh
# Fill in your actual Cloud SQL IP, MongoDB IP, GCS bucket name, etc.

# Add to /etc/profile.d/ so they load on boot
sudo cp /opt/app/env.sh /etc/profile.d/cloud-library-env.sh
source /opt/app/env.sh
```

### Start with PM2 and save:
```bash
cd /opt/app
pm2 start pm2/ecosystem.config.js
pm2 save
pm2 startup
# Run the command PM2 outputs (sudo env PATH=... pm2 startup ...)
```

### Verify everything works:
```bash
pm2 monit
# Should show all 6 services running
curl http://localhost:8761   # Eureka dashboard
curl http://localhost:8080/members   # Through gateway
```

### Stop the VM and create a disk image:
1. Stop `golden-vm` in GCP Console
2. Go to **Compute Engine → Images → Create Image**
3. Name: `cloud-library-image-v1`
4. Source: Disk of `golden-vm`
5. Click Create

---

## STEP 9: Instance Templates

Create an instance template for each service group.

Go to **Compute Engine → Instance Templates → Create**:

### Template: platform-template
- Machine type: `e2-medium`
- Boot disk: your custom image `cloud-library-image-v1`
- Network: your VPC
- Network tags: `gateway`, `eureka`
- Startup script:
```bash
#!/bin/bash
source /etc/profile.d/cloud-library-env.sh
cd /opt/app
pm2 resurrect || pm2 start pm2/ecosystem.config.js
pm2 save
```

### Template: services-template
- Same as above but with network tag: `services`
- Same startup script

(You can use one template for all, or separate ones — both work.)

---

## STEP 10: Managed Instance Groups (MIGs) + Auto Scaling

Go to **Compute Engine → Instance Groups → Create**:

### For each service group, create a MIG:

| MIG Name | Template | Min | Max | Zones | Health Check |
|----------|----------|-----|-----|-------|--------------|
| config-server-mig | platform-template | 2 | 3 | multi-zone | /actuator/health on port 8888 |
| eureka-server-mig | platform-template | 2 | 3 | multi-zone | /actuator/health on port 8761 |
| gateway-mig | platform-template | 2 | 4 | multi-zone | /actuator/health on port 8080 |
| member-service-mig | services-template | 2 | 4 | multi-zone | /actuator/health on port 8081 |
| book-service-mig | services-template | 2 | 4 | multi-zone | /actuator/health on port 8082 |
| borrowing-service-mig | services-template | 2 | 4 | multi-zone | /actuator/health on port 8083 |

Important settings for each MIG:
- Location: **Multiple zones** (for HA across zones)
- Autoscaling: ON, based on CPU utilization (60%)
- Autohealing: use the health check

### Create Health Checks
Go to **Compute Engine → Health Checks → Create**:

| Name | Protocol | Port | Path |
|------|----------|------|------|
| hc-config | HTTP | 8888 | /actuator/health |
| hc-eureka | HTTP | 8761 | /actuator/health |
| hc-gateway | HTTP | 8080 | /actuator/health |
| hc-member | HTTP | 8081 | /actuator/health |
| hc-book | HTTP | 8082 | /actuator/health |
| hc-borrowing | HTTP | 8083 | /actuator/health |

---

## STEP 11: Load Balancer

1. Go to **Network Services → Load Balancing → Create**
2. Type: **HTTP(S) Load Balancer** (external)
3. Backend:
   - Backend service: `gateway-mig`
   - Health check: `hc-gateway`
   - Port: 8080
4. Frontend:
   - Protocol: HTTP
   - Port: 80
   - IP: Create a new static IP (note it!)
5. Click Create

The Load Balancer IP is your public entry point.

---

## STEP 12: Cloud DNS

1. Go to **Network Services → Cloud DNS → Create Zone**
2. Zone name: `cloud-library-zone`
3. DNS name: your domain (or use the IP directly)
4. Add an A record pointing to the Load Balancer IP

(If you don't have a domain, just use the LB IP address directly.)

---

## STEP 13: Update Frontend

Edit `frontend/js/api.js` and change `GATEWAY_URL`:
```javascript
const GATEWAY_URL = 'http://YOUR_LOAD_BALANCER_IP';
```

Host the frontend on any static hosting (or just open index.html locally).

---

## STEP 14: Verify Everything

```bash
# Test through Load Balancer
curl http://YOUR_LB_IP/members
curl http://YOUR_LB_IP/books
curl http://YOUR_LB_IP/borrowings

# Check Eureka Dashboard
# Open: http://EUREKA_PUBLIC_IP:8761

# SSH into VMs and check PM2
gcloud compute ssh VM_NAME --zone=ZONE
pm2 monit
```

---

## GCP Resources Checklist (for screen recording)

Show ALL of these in your screen recording:
- [ ] VM Instance Groups (6 MIGs)
- [ ] Virtual Machines (list all running VMs)
- [ ] VM Instance Templates
- [ ] Disk Images (your golden image)
- [ ] Health Checks (6 health checks)
- [ ] Cloud DNS zone + records
- [ ] Load Balancer configuration
- [ ] Cloud NAT Gateway
- [ ] Cloud SQL Instance (show databases)
- [ ] Cloud Storage Bucket (show the bucket)
- [ ] Cloud Router
- [ ] VPC Network (show subnets)
- [ ] Firewall Rules (show all rules)
- [ ] SSH into each VM → run `pm2 monit`
