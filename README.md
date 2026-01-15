# Lab M2.03 - Configure Multi-Tier Security Groups

**Course:** Cloud Engineering Bootcamp - Week 2  
**Module:** Core Services & Secure Deployment  
**Lab Type:** Individual  
**Estimated Time:** 60-75 minutes

---

## 📋 Overview

Design and implement a multi-tier security architecture using AWS Security Groups. Learn defense-in-depth principles by creating separate security groups for different application tiers.

## 🎯 Learning Objectives

- Design multi-tier security architecture
- Implement security group references
- Configure bastion host access patterns
- Apply least privilege principles
- Test and verify security configurations

## 🏗️ Architecture

This lab implements a 3-tier architecture:
- **Bastion Tier**: SSH jump host
- **Web Tier**: Public-facing web servers
- **Application Tier**: Backend application servers
- **Database Tier**: Data storage (simulated)

## 📁 Repository Structure

```
ce-lab-multi-tier-security/
├── README.md (update with your documentation)
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

## 📝 What to Include

### 1. Architecture Folder
- **architecture-diagram.png**: Visual diagram of your security architecture
- **security-groups-design.md**: Explanation of your security design decisions
- **traffic-flow.md**: Document how traffic flows through each tier

### 2. Security Groups Folder
For each security group, document:
- Inbound rules (with justification)
- Outbound rules (with justification)
- Security group references used
- CIDR ranges and why you chose them

### 3. Tests Folder
- **security-test-results.md**: Results of your security tests
- **test-commands.sh**: Commands used to test connectivity between tiers

### 4. Screenshots
- All security groups in AWS Console
- Detailed view of web tier security group rules
- Successful traffic flow test
- Overall architecture in console

### 5. README.md (Update This!)
Document:
- Your security design philosophy
- How each tier protects the next
- Why you made specific rule decisions
- Testing methodology and results
- Challenges and learnings

## 🔐 Security Group Design Template

### Bastion Security Group
```
Purpose: SSH jump host for accessing private instances

Inbound:
- Port 22 (SSH) from YOUR_IP_ADDRESS/32

Outbound:
- Port 22 (SSH) to web tier SG
- Port 22 (SSH) to app tier SG
```

### Web Tier Security Group
```
Purpose: Public-facing web servers

Inbound:
- Port 80 (HTTP) from 0.0.0.0/0
- Port 443 (HTTPS) from 0.0.0.0/0
- Port 22 (SSH) from bastion SG

Outbound:
- Port 8080 to app tier SG
- Port 443 to 0.0.0.0/0 (for updates)
```

### Application Tier Security Group
```
Purpose: Backend application servers

Inbound:
- Port 8080 from web tier SG
- Port 22 (SSH) from bastion SG

Outbound:
- Port 3306/5432 to database tier SG
- Port 443 to 0.0.0.0/0 (for updates)
```

### Database Tier Security Group
```
Purpose: Database servers (simulated)

Inbound:
- Port 3306 or 5432 from app tier SG only
- Port 22 (SSH) from bastion SG

Outbound:
- Port 443 to 0.0.0.0/0 (for updates only)
```

## ✅ Testing Checklist

- [ ] Can SSH to bastion from your IP
- [ ] Can SSH from bastion to web tier
- [ ] Can SSH from bastion to app tier
- [ ] Cannot SSH directly to web tier from internet
- [ ] Cannot SSH directly to app tier from internet
- [ ] Web tier can reach app tier on port 8080
- [ ] App tier can reach database tier on DB port
- [ ] Web tier CANNOT reach database tier directly

## 📚 Key Concepts

**Defense in Depth**: Multiple layers of security  
**Least Privilege**: Only allow necessary access  
**Security Group References**: Reference other SGs instead of IPs  
**Bastion Host**: Secure entry point to private network  

## 🚀 Submission

1. Complete all security group configurations
2. Create architecture diagrams
3. Document all rules and decisions
4. Run security tests and document results
5. Update this README with your findings
6. Commit and push all files
7. Submit repository URL

---

**Remember:** Security is not a one-time task, it's an ongoing practice! 🔒
