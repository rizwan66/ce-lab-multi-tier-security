# Traffic Flow Analysis

## Allowed Traffic Paths

### 1. Public Web Request (Internet → Web → App)

```
User Browser
    │  HTTP:80 / HTTPS:443
    ▼
Web Instance (sg-web-tier)
    │  HTTP:8080  [allowed by sg-web-tier outbound + sg-app-tier inbound]
    ▼
App Instance (sg-app-tier)
    │  MySQL:3306  [allowed by sg-app-tier outbound + sg-database inbound]
    ▼
DB Instance (sg-database)
```

**Each hop is explicitly allowed** — traffic cannot skip tiers.

---

### 2. Admin SSH via Bastion

```
Admin Machine (YOUR_IP/32)
    │  SSH:22
    ▼
Bastion (sg-bastion)
    │  SSH:22  [allowed outbound to each tier's SG]
    ├──▶ Web Instance (sg-web-tier)
    ├──▶ App Instance (sg-app-tier)
    └──▶ DB Instance (sg-database)
```

---

## Blocked Traffic Paths

### 3. Direct SSH from Internet (BLOCKED)

```
Admin Machine
    │  SSH:22
    ▼
Web Instance  ✗  (sg-web-tier has no inbound SSH from 0.0.0.0/0)
```
Result: **Connection timeout** — the security group silently drops the packet.

---

### 4. Web Tier to Database Direct (BLOCKED)

```
Web Instance
    │  TCP:3306
    ▼
DB Instance  ✗  (sg-database only accepts 3306 from sg-app-tier)
```
Result: **Connection refused / timeout** — even if the web instance is compromised, it cannot reach MySQL.

---

### 5. Internet to App Tier (BLOCKED)

```
Internet
    │  TCP:8080
    ▼
App Instance  ✗  (sg-app-tier inbound 8080 only from sg-web-tier)
```
Result: **No route** — the app instance has no public IP assignment and the SG would block it regardless.

---

## Port Reference Summary

| Port | Protocol | Used By | Direction |
|------|----------|---------|-----------|
| 22   | SSH      | Bastion → All tiers | Admin access |
| 80   | HTTP     | Internet → Web | Public traffic |
| 443  | HTTPS    | Internet → Web, All → Internet | Public + outbound |
| 8080 | HTTP     | Web → App | Internal app traffic |
| 3306 | MySQL    | App → DB | Database queries |

## Defense-in-Depth Summary

| Attack Scenario | Blocked By |
|----------------|------------|
| SSH brute force from internet | sg-bastion restricts inbound to /32 IP |
| Direct DB access from web tier | sg-database only allows 3306 from sg-app-tier |
| App tier exposed to internet | sg-app-tier has no inbound from 0.0.0.0/0 |
| Lateral movement after web compromise | Web tier has no outbound rule to 3306 |
| Direct SSH to any instance | All SSH inbound restricted to sg-bastion source |
