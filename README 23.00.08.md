# CE Lab: Multi-Tier Security Groups

A hands-on AWS lab demonstrating defense-in-depth using layered security groups across a three-tier web application architecture.

## Architecture Overview

```
Internet
   │
   ▼
[Web Tier]  ──── sg-web-tier (HTTP/HTTPS from internet, SSH from bastion)
   │
   ▼ port 8080
[App Tier]  ──── sg-app-tier (port 8080 from web, SSH from bastion)
   │
   ▼ port 3306
[DB Tier]   ──── sg-database (MySQL from app only, SSH from bastion)

[Bastion]   ──── sg-bastion (SSH from your IP only)
```

## Lab Goals

- Understand how security groups enforce least-privilege access between tiers
- Verify that lateral traffic (e.g., web → DB directly) is blocked
- Demonstrate bastion host SSH access pattern
- Simulate end-to-end application traffic flow

## Prerequisites

- AWS account with EC2 access
- AWS CLI configured (`aws configure`)
- Your public IP address (`curl ifconfig.me`)
- Key pair created in your target region

## Lab Steps

### Step 1: Create Security Groups

See [security-groups/](security-groups/) for the exact rules.

Create using CLI:

```bash
# Set your VPC ID
export VPC_ID=vpc-xxxxxxxxxx
export MY_IP=$(curl -s ifconfig.me)/32

# Create all 4 security groups
bash tests/test-commands.sh create-sgs
```

Or create manually via the AWS Console (EC2 → Security Groups → Create).

### Step 2: Launch Instances

**Option A (simpler):** Launch 1 instance, attach sg-web-tier + sg-app-tier + sg-database, use different ports to simulate tiers.

**Option B (realistic):** Launch 3 EC2 instances:
| Instance | Security Groups | Subnet |
|----------|----------------|--------|
| bastion  | sg-bastion     | Public |
| web      | sg-web-tier    | Public |
| app      | sg-app-tier    | Private |
| db       | sg-database    | Private |

### Step 3: Set Up Simulated Services

**On DB instance** — simulate MySQL:
```bash
while true; do echo "MySQL Connection Accepted" | nc -l 3306; done &
```

**On App instance** — simulate app server:
```bash
cat > server.js <<EOF
const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200);
  res.end('Hello from App Tier\n');
});
server.listen(8080);
console.log('App listening on port 8080');
EOF
node server.js &
```

**On Web instance** — configure Nginx reverse proxy:
```bash
sudo yum install -y nginx
sudo tee /etc/nginx/conf.d/app.conf <<EOF
server {
    listen 80;
    location / {
        proxy_pass http://APP_INSTANCE_IP:8080;
    }
}
EOF
sudo systemctl start nginx
```

### Step 4: Run Tests

```bash
# End-to-end test
curl http://WEB_INSTANCE_PUBLIC_IP
# Expected: "Hello from App Tier"
```

See full test results in [tests/security-test-results.md](tests/security-test-results.md).

## Repository Structure

```
ce-lab-multi-tier-security/
├── README.md
├── architecture/
│   ├── architecture-diagram.png
│   ├── security-groups-design.md
│   └── traffic-flow.md
├── security-groups/
│   ├── sg-bastion-rules.txt
│   ├── sg-web-tier-rules.txt
│   ├── sg-app-tier-rules.txt
│   └── sg-database-rules.txt
├── tests/
│   ├── security-test-results.md
│   └── test-commands.sh
└── screenshots/
    ├── 01-security-groups-list.png
    ├── 02-web-tier-rules.png
    ├── 03-traffic-flow-test.png
    └── 04-architecture-console.png
```

## Key Security Concepts Demonstrated

| Concept | Implementation |
|---------|---------------|
| Least privilege | Each tier only allows traffic it needs |
| Defense in depth | Multiple layers; breach of one doesn't expose all |
| Bastion pattern | SSH access only through dedicated jump host |
| Micro-segmentation | App and DB tiers are not internet-accessible |
| Deny by default | All unspecified traffic is dropped |
