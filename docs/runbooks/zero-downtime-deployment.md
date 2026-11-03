# Zero-Downtime Deployment Runbook

This guide covers rolling updates and zero-downtime application releases on the 3-Tier AWS Architecture.

---

## 🔄 Deployment Strategies

### 1. Rolling Instance Refresh (Auto Scaling)

When updating AMI IDs, launch templates, or foundational OS packages:

```bash
# 1. Trigger rolling instance refresh with 50% minimum healthy percentage
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name aws-infra-prod-app-asg \
  --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 180}'

# 2. Monitor refresh status
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name aws-infra-prod-app-asg
```

---

### 2. Ansible Rolling In-Place Deployment

To deploy application updates without terminating underlying EC2 instances:

```bash
# Execute deployment in batches of 1 with serial execution
cd ansible
ansible-playbook playbooks/appservers.yml \
  -i inventory/aws_ec2.yml \
  --forks 1
```

Because Nginx and the Node.js application implement graceful connection draining (`SIGTERM` handling and keepalive pools), ongoing requests complete before the service restarts.

---

### 3. Immediate Rollback Protocol

If a release introduces a regression:

```bash
# Cancel ongoing ASG refresh
aws autoscaling cancel-instance-refresh \
  --auto-scaling-group-name aws-infra-prod-app-asg

# Roll back to previous Git commit & re-run deployment
git checkout HEAD~1
cd ansible && ansible-playbook playbooks/site.yml -i inventory/aws_ec2.yml
```

---

## 🔍 Post-Deployment Health Check

Verify all endpoints respond with HTTP 200:

```bash
# Web Tier Ingress Check
curl -Is https://<EXTERNAL_ALB_DNS>/health | head -n 1

# API Backend Status Check
curl -s https://<EXTERNAL_ALB_DNS>/api/status | jq .
```
