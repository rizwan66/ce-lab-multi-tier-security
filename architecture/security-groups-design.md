# Security Groups Design

## Overview

Four security groups implement a defense-in-depth model for a three-tier web application. Each group enforces least-privilege: instances only accept traffic from explicitly trusted sources on required ports.

---

## sg-bastion

**Purpose:** Controls the jump host used for all administrative SSH access. It is the only entry point for SSH into the entire environment.

| Direction | Protocol | Port | Source/Destination | Reason |
|-----------|----------|------|--------------------|--------|
| Inbound   | TCP      | 22   | YOUR_IP/32         | Only your machine can SSH to the bastion |
| Outbound  | TCP      | 22   | sg-web-tier        | Bastion can reach web instances |
| Outbound  | TCP      | 22   | sg-app-tier        | Bastion can reach app instances |
| Outbound  | TCP      | 22   | sg-database        | Bastion can reach DB instances |

**Design rationale:** Restricting inbound SSH to a single IP (`/32`) eliminates brute-force exposure. All SSH sessions to other tiers must originate here — no direct access from the internet.

---

## sg-web-tier

**Purpose:** Internet-facing tier that serves HTTP/HTTPS traffic and proxies requests to the app tier.

| Direction | Protocol | Port | Source/Destination | Reason |
|-----------|----------|------|--------------------|--------|
| Inbound   | TCP      | 80   | 0.0.0.0/0          | Public HTTP access |
| Inbound   | TCP      | 443  | 0.0.0.0/0          | Public HTTPS access |
| Inbound   | TCP      | 22   | sg-bastion         | SSH only from bastion |
| Outbound  | TCP      | 8080 | sg-app-tier        | Forward requests to app tier |
| Outbound  | TCP      | 443  | 0.0.0.0/0          | HTTPS calls to external services / AWS APIs |

**Design rationale:** The web tier is internet-facing but has no direct path to the database. It can only push traffic to the app tier on the application port (8080), not MySQL (3306).

---

## sg-app-tier

**Purpose:** Business logic layer. Accepts traffic only from the web tier, never directly from the internet.

| Direction | Protocol | Port | Source/Destination | Reason |
|-----------|----------|------|--------------------|--------|
| Inbound   | TCP      | 8080 | sg-web-tier        | Application traffic from web tier only |
| Inbound   | TCP      | 22   | sg-bastion         | SSH only from bastion |
| Outbound  | TCP      | 3306 | sg-database        | Query the database |
| Outbound  | TCP      | 443  | 0.0.0.0/0          | HTTPS calls to external APIs |

**Design rationale:** The app tier is completely invisible to the internet. A compromised web server cannot directly pivot to the database — it must go through the app tier, adding an additional detection layer.

---

## sg-database

**Purpose:** Protects the data layer. Only the app tier can connect on the MySQL port.

| Direction | Protocol | Port | Source/Destination | Reason |
|-----------|----------|------|--------------------|--------|
| Inbound   | TCP      | 3306 | sg-app-tier        | MySQL connections from app tier only |
| Inbound   | TCP      | 22   | sg-bastion         | SSH only from bastion |
| Outbound  | TCP      | 443  | 0.0.0.0/0          | HTTPS for software updates / AWS API calls |

**Design rationale:** MySQL is never exposed to the web tier or internet. Even if the app tier is compromised, lateral movement from a web instance directly to port 3306 is blocked at the security group level.

---

## Security Group Reference Map

```
sg-bastion ──SSH──▶ sg-web-tier
sg-bastion ──SSH──▶ sg-app-tier
sg-bastion ──SSH──▶ sg-database

Internet   ──80/443──▶ sg-web-tier
sg-web-tier ──8080──▶ sg-app-tier
sg-app-tier ──3306──▶ sg-database

sg-web-tier ✗──3306──▶ sg-database  (BLOCKED)
Internet    ✗──22───▶ sg-web-tier   (BLOCKED — no direct SSH)
```
