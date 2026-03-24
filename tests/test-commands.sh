#!/bin/bash
# =============================================================
# Multi-Tier Security Lab - Test Commands
# =============================================================
# Usage:
#   chmod +x test-commands.sh
#   ./test-commands.sh
#
# Before running, set these environment variables:
#   export VPC_ID=vpc-xxxxxxxxxx
#   export MY_IP=$(curl -s ifconfig.me)/32
#   export KEY_NAME=your-key-pair-name
#   export REGION=us-east-1
#   export WEB_PUBLIC_IP=x.x.x.x
#   export BASTION_PUBLIC_IP=x.x.x.x
#   export WEB_PRIVATE_IP=10.x.x.x
#   export APP_PRIVATE_IP=10.x.x.x
#   export DB_PRIVATE_IP=10.x.x.x
# =============================================================

set -e

# -------------------------------------------------------
# SECTION 1: Create Security Groups via AWS CLI
# -------------------------------------------------------
create_security_groups() {
  echo "=== Creating Security Groups ==="

  # sg-bastion
  BASTION_SG=$(aws ec2 create-security-group \
    --group-name sg-bastion \
    --description "Bastion host - SSH entry point" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)
  echo "Created sg-bastion: $BASTION_SG"

  # sg-web-tier
  WEB_SG=$(aws ec2 create-security-group \
    --group-name sg-web-tier \
    --description "Web tier - public HTTP/HTTPS" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)
  echo "Created sg-web-tier: $WEB_SG"

  # sg-app-tier
  APP_SG=$(aws ec2 create-security-group \
    --group-name sg-app-tier \
    --description "App tier - internal only" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)
  echo "Created sg-app-tier: $APP_SG"

  # sg-database
  DB_SG=$(aws ec2 create-security-group \
    --group-name sg-database \
    --description "Database tier - MySQL from app only" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)
  echo "Created sg-database: $DB_SG"

  echo ""
  echo "=== Adding Inbound Rules ==="

  # sg-bastion inbound: SSH from your IP
  aws ec2 authorize-security-group-ingress \
    --group-id "$BASTION_SG" \
    --protocol tcp --port 22 --cidr "$MY_IP"
  echo "sg-bastion: SSH from $MY_IP ✓"

  # sg-web-tier inbound: HTTP, HTTPS from internet, SSH from bastion
  aws ec2 authorize-security-group-ingress \
    --group-id "$WEB_SG" \
    --protocol tcp --port 80 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress \
    --group-id "$WEB_SG" \
    --protocol tcp --port 443 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress \
    --group-id "$WEB_SG" \
    --protocol tcp --port 22 \
    --source-group "$BASTION_SG"
  echo "sg-web-tier: HTTP, HTTPS, SSH from bastion ✓"

  # sg-app-tier inbound: 8080 from web, SSH from bastion
  aws ec2 authorize-security-group-ingress \
    --group-id "$APP_SG" \
    --protocol tcp --port 8080 \
    --source-group "$WEB_SG"
  aws ec2 authorize-security-group-ingress \
    --group-id "$APP_SG" \
    --protocol tcp --port 22 \
    --source-group "$BASTION_SG"
  echo "sg-app-tier: 8080 from web, SSH from bastion ✓"

  # sg-database inbound: 3306 from app, SSH from bastion
  aws ec2 authorize-security-group-ingress \
    --group-id "$DB_SG" \
    --protocol tcp --port 3306 \
    --source-group "$APP_SG"
  aws ec2 authorize-security-group-ingress \
    --group-id "$DB_SG" \
    --protocol tcp --port 22 \
    --source-group "$BASTION_SG"
  echo "sg-database: 3306 from app, SSH from bastion ✓"

  echo ""
  echo "=== Adding Outbound Rules ==="
  # AWS adds a default allow-all outbound; remove it and add specific rules

  # sg-bastion outbound: SSH to each tier
  aws ec2 revoke-security-group-egress \
    --group-id "$BASTION_SG" \
    --protocol -1 --port all --cidr 0.0.0.0/0 2>/dev/null || true
  aws ec2 authorize-security-group-egress \
    --group-id "$BASTION_SG" \
    --protocol tcp --port 22 --destination-group "$WEB_SG"
  aws ec2 authorize-security-group-egress \
    --group-id "$BASTION_SG" \
    --protocol tcp --port 22 --destination-group "$APP_SG"
  aws ec2 authorize-security-group-egress \
    --group-id "$BASTION_SG" \
    --protocol tcp --port 22 --destination-group "$DB_SG"
  echo "sg-bastion outbound: SSH to all tiers ✓"

  # sg-web-tier outbound: 8080 to app, 443 to internet
  aws ec2 revoke-security-group-egress \
    --group-id "$WEB_SG" \
    --protocol -1 --port all --cidr 0.0.0.0/0 2>/dev/null || true
  aws ec2 authorize-security-group-egress \
    --group-id "$WEB_SG" \
    --protocol tcp --port 8080 --destination-group "$APP_SG"
  aws ec2 authorize-security-group-egress \
    --group-id "$WEB_SG" \
    --protocol tcp --port 443 --cidr 0.0.0.0/0
  echo "sg-web-tier outbound: 8080 to app, 443 to internet ✓"

  # sg-app-tier outbound: 3306 to db, 443 to internet
  aws ec2 revoke-security-group-egress \
    --group-id "$APP_SG" \
    --protocol -1 --port all --cidr 0.0.0.0/0 2>/dev/null || true
  aws ec2 authorize-security-group-egress \
    --group-id "$APP_SG" \
    --protocol tcp --port 3306 --destination-group "$DB_SG"
  aws ec2 authorize-security-group-egress \
    --group-id "$APP_SG" \
    --protocol tcp --port 443 --cidr 0.0.0.0/0
  echo "sg-app-tier outbound: 3306 to db, 443 to internet ✓"

  # sg-database outbound: 443 to internet only
  aws ec2 revoke-security-group-egress \
    --group-id "$DB_SG" \
    --protocol -1 --port all --cidr 0.0.0.0/0 2>/dev/null || true
  aws ec2 authorize-security-group-egress \
    --group-id "$DB_SG" \
    --protocol tcp --port 443 --cidr 0.0.0.0/0
  echo "sg-database outbound: 443 to internet ✓"

  echo ""
  echo "All security groups created successfully!"
  echo "BASTION_SG=$BASTION_SG  WEB_SG=$WEB_SG  APP_SG=$APP_SG  DB_SG=$DB_SG"
}

# -------------------------------------------------------
# SECTION 2: Traffic Tests
# -------------------------------------------------------

test_web_public_access() {
  echo "=== Test 1: Web Tier Public HTTP Access ==="
  echo "Command: curl -s -o /dev/null -w '%{http_code}' http://$WEB_PUBLIC_IP"
  STATUS=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://$WEB_PUBLIC_IP" || echo "FAILED")
  if [ "$STATUS" = "200" ]; then
    echo "RESULT: PASS - HTTP 200 received"
  else
    echo "RESULT: HTTP status $STATUS"
  fi
  echo ""
}

test_direct_ssh_blocked() {
  echo "=== Test 3: Direct SSH to Web (Should Be BLOCKED) ==="
  echo "Command: ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$WEB_PUBLIC_IP"
  if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes \
      "ec2-user@$WEB_PUBLIC_IP" exit 2>/dev/null; then
    echo "RESULT: FAIL - SSH succeeded (unexpected!)"
  else
    echo "RESULT: PASS - SSH blocked/timed out as expected"
  fi
  echo ""
}

test_app_from_web() {
  echo "=== Test 4: App Tier from Web Tier (port 8080) ==="
  echo "SSH to web, then nc -zv $APP_PRIVATE_IP 8080"
  ssh -o StrictHostKeyChecking=no -i "${KEY_NAME}.pem" \
      -J "ec2-user@$BASTION_PUBLIC_IP" \
      "ec2-user@$WEB_PRIVATE_IP" \
      "nc -zv $APP_PRIVATE_IP 8080 && echo 'RESULT: PASS' || echo 'RESULT: FAIL'"
  echo ""
}

test_db_from_app() {
  echo "=== Test 5: DB Tier from App Tier (port 3306) ==="
  echo "SSH to app (via bastion), then nc -zv $DB_PRIVATE_IP 3306"
  ssh -o StrictHostKeyChecking=no -i "${KEY_NAME}.pem" \
      -J "ec2-user@$BASTION_PUBLIC_IP" \
      "ec2-user@$APP_PRIVATE_IP" \
      "nc -zv $DB_PRIVATE_IP 3306 && echo 'RESULT: PASS' || echo 'RESULT: FAIL'"
  echo ""
}

test_db_from_web_blocked() {
  echo "=== Test 6: DB Tier from Web Tier (Should Be BLOCKED) ==="
  echo "SSH to web, then nc -zv $DB_PRIVATE_IP 3306 (expect timeout)"
  ssh -o StrictHostKeyChecking=no -i "${KEY_NAME}.pem" \
      -J "ec2-user@$BASTION_PUBLIC_IP" \
      "ec2-user@$WEB_PRIVATE_IP" \
      "nc -zv -w 5 $DB_PRIVATE_IP 3306 && echo 'RESULT: FAIL (unexpected)' || echo 'RESULT: PASS - blocked as expected'"
  echo ""
}

test_end_to_end() {
  echo "=== End-to-End Test: Internet → Web → App ==="
  echo "Command: curl http://$WEB_PUBLIC_IP"
  RESPONSE=$(curl -s --max-time 15 "http://$WEB_PUBLIC_IP" || echo "FAILED")
  echo "Response: $RESPONSE"
  if echo "$RESPONSE" | grep -q "App Tier"; then
    echo "RESULT: PASS - Got response from App Tier"
  else
    echo "RESULT: Check nginx config and app server"
  fi
  echo ""
}

run_all_tests() {
  echo "=============================================="
  echo "  Multi-Tier Security Lab - Test Suite"
  echo "=============================================="
  echo ""
  test_web_public_access
  test_direct_ssh_blocked
  test_app_from_web
  test_db_from_app
  test_db_from_web_blocked
  test_end_to_end
  echo "All tests complete. See security-test-results.md for expected outcomes."
}

# -------------------------------------------------------
# Entry point
# -------------------------------------------------------
case "${1:-run-tests}" in
  create-sgs) create_security_groups ;;
  run-tests)  run_all_tests ;;
  *)
    echo "Usage: $0 [create-sgs|run-tests]"
    echo "  create-sgs  - Create all 4 security groups via AWS CLI"
    echo "  run-tests   - Run all traffic flow tests"
    ;;
esac
