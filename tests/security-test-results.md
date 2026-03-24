# Security Test Results

**Lab:** Multi-Tier Security Groups
**Date:** ___________
**Region:** ___________
**Instance Option:** [ ] Option A (1 instance) / [ ] Option B (3 instances)

---

## Instance Information

| Role     | Instance ID | Public IP | Private IP | Security Group(s) |
|----------|-------------|-----------|------------|-------------------|
| Bastion  |             |           |            | sg-bastion        |
| Web      |             |           |            | sg-web-tier       |
| App      |             |           |            | sg-app-tier       |
| Database |             |           |            | sg-database       |

---

## Test Results

### Test 1: Web Tier Public HTTP Access
**Expected:** PASS (HTTP 200 from internet)

```
Command: curl http://WEB_INSTANCE_PUBLIC_IP
Result: [ ] PASS  [ ] FAIL
HTTP Status: ______
Notes:
```

---

### Test 2: SSH via Bastion to Web Instance
**Expected:** PASS (SSH connects through bastion)

```
Command: ssh -J ec2-user@BASTION_IP ec2-user@WEB_PRIVATE_IP
Result: [ ] PASS  [ ] FAIL
Notes:
```

---

### Test 3: Direct SSH to Web Instance (Should Fail)
**Expected:** FAIL / Connection timeout (SSH not allowed from internet)

```
Command: ssh ec2-user@WEB_INSTANCE_PUBLIC_IP
Result: [ ] PASS (correctly blocked)  [ ] FAIL (incorrectly allowed)
Behavior observed: [ ] Timeout  [ ] Connection refused  [ ] Connected
Notes:
```

---

### Test 4: App Tier Reachable from Web Tier (port 8080)
**Expected:** PASS (web → app on 8080 is allowed)

```
# From web instance:
Command: nc -zv APP_PRIVATE_IP 8080
Result: [ ] PASS  [ ] FAIL
Output:
```

---

### Test 5: Database Reachable from App Tier (port 3306)
**Expected:** PASS (app → db on 3306 is allowed)

```
# From app instance:
Command: nc -zv DB_PRIVATE_IP 3306
Result: [ ] PASS  [ ] FAIL
Output:
```

---

### Test 6: Database NOT Reachable from Web Tier (Should Fail)
**Expected:** FAIL / Timeout (web → db on 3306 is blocked)

```
# From web instance:
Command: nc -zv -w 5 DB_PRIVATE_IP 3306
Result: [ ] PASS (correctly blocked)  [ ] FAIL (incorrectly allowed)
Behavior observed: [ ] Timeout  [ ] Connection refused
Notes:
```

---

### Test 7: End-to-End Application Flow
**Expected:** PASS — curl returns "Hello from App Tier"

```
Command: curl http://WEB_INSTANCE_PUBLIC_IP
Result: [ ] PASS  [ ] FAIL
Response body:
```

---

## Summary Table

| Test | Description | Expected | Actual | Pass/Fail |
|------|-------------|----------|--------|-----------|
| 1 | HTTP to web from internet | 200 OK | | |
| 2 | SSH via bastion → web | Connected | | |
| 3 | Direct SSH to web (blocked) | Timeout | | |
| 4 | Web → App port 8080 | Connected | | |
| 5 | App → DB port 3306 | Connected | | |
| 6 | Web → DB port 3306 (blocked) | Timeout | | |
| 7 | End-to-end curl | "Hello from App Tier" | | |

---

## Observations & Learnings

> Fill in after completing all tests

1. **What happened when SSH was attempted directly to the web instance?**

   _________________________________________

2. **Did the security group block the web-to-database path as expected? Why does this matter?**

   _________________________________________

3. **What is the purpose of the bastion host pattern?**

   _________________________________________

4. **How would you improve this architecture for production?**

   _________________________________________

---

## Security Group Verification (AWS CLI)

Capture the actual rules applied to verify configuration:

```bash
# List all security groups created
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=sg-bastion,sg-web-tier,sg-app-tier,sg-database" \
  --query 'SecurityGroups[*].{Name:GroupName,ID:GroupId,Inbound:IpPermissions,Outbound:IpPermissionsEgress}' \
  --output table
```

Output:
```
[paste aws cli output here]
```
