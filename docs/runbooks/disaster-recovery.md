# Disaster Recovery (DR) Runbook

This runbook defines emergency procedures, failover mechanisms, and recovery protocols for the Automated AWS 3-Tier Infrastructure.

---

## 🎯 Objectives & Metrics

| Metric | Target | Description |
|:-------|:-------|:------------|
| **RPO (Recovery Point Objective)** | < 1 minute | Maximum acceptable data loss during a failure |
| **RTO (Recovery Time Objective)** | < 5 minutes | Maximum acceptable downtime before service restoration |

---

## 🚨 Incident Scenarios & Procedures

### Scenario 1: Availability Zone (AZ) Outage

The architecture is deployed across dual AZs (`us-east-1a` and `us-east-1b`). If an entire AWS data center goes offline:

1. **ALB Routing**:
   - The Application Load Balancers continuously perform health checks across both AZs.
   - Traffic is automatically shifted away from failing instances in the affected AZ within 30 seconds.
2. **Auto Scaling Rebalancing**:
   - The Auto Scaling Groups detect unhealthy nodes and spin up replacement instances in the surviving AZ.
   - Run verification command:
     ```bash
     aws autoscaling describe-auto-scaling-groups \
       --auto-scaling-group-names aws-infra-prod-web-asg aws-infra-prod-app-asg \
       --query "AutoScalingGroups[*].Instances[*].[InstanceId,AvailabilityZone,HealthStatus]" \
       --output table
     ```
3. **Database Failover**:
   - If the primary RDS instance was in the degraded AZ, Amazon RDS automatically initiates a DNS failover to the synchronous standby replica in the surviving AZ (typically completes within 60–120 seconds).

---

### Scenario 2: RDS Database Manual Failover Test

To test or trigger a controlled Multi-AZ failover:

```bash
# Force failover to standby replica
aws rds reboot-db-instance \
  --db-instance-identifier aws-infra-prod-mysql \
  --force-failover
```

Monitor failover progress:
```bash
aws rds describe-db-instances \
  --db-instance-identifier aws-infra-prod-mysql \
  --query "DBInstances[0].[DBInstanceStatus,SecondaryAvailabilityZone]" \
  --output table
```

---

### Scenario 3: Point-In-Time Database Recovery (PITR)

If data is corrupted or accidentally deleted:

1. **Identify Timestamp**: Note the exact UTC timestamp prior to the incident.
2. **Restore Database**:
   ```bash
   aws rds restore-db-instance-to-point-in-time \
     --source-db-instance-identifier aws-infra-prod-mysql \
     --target-db-instance-identifier aws-infra-prod-mysql-restored \
     --restore-time 2026-11-03T14:30:00Z \
     --db-subnet-group-name aws-infra-prod-db-subnet-group
   ```
3. **Update Terraform / Application**: Point application environment variables to the new database endpoint or rename instances during maintenance.

---

### Scenario 4: Terraform State Lock Resolution

If a CI/CD pipeline or local deploy crashed mid-execution, leaving a stale lock in DynamoDB:

```bash
# 1. Inspect DynamoDB Lock Table
aws dynamodb scan --table-name terraform-state-lock

# 2. Release Lock with Lock ID (e.g., 995adae8-5a3c-4d8a)
cd terraform/environments/prod
terraform force-unlock <LOCK_ID>
```

---

## 📞 Escalation & Verification Checklist

- [ ] Check CloudWatch Alarms: `aws cloudwatch describe-alarms --state-value ALARM`
- [ ] Inspect ALB Target Group Health: `aws elbv2 describe-target-health --target-group-arn <TG_ARN>`
- [ ] Validate Nginx & Node.js service logs via CloudWatch Logs: `/ec2/app/messages`
- [ ] Verify WAF blocked requests: CloudWatch Metric `BlockedRequests` under namespace `AWS/WAFV2`
