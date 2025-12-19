# AWS DevOps Professional Projects — Step-by-Step Guides

A comprehensive walkthrough for deploying all seven projects in sequence, including setup, validation, and teardown.

**Estimated Total Time:** 8-12 hours (spread across multiple sessions recommended)
**Last Updated:** 2025-12-19

---

## Guide Structure

| Guide | Description |
|-------|-------------|
| [00-prerequisites.md](00-prerequisites.md) | Tools, AWS account setup, IAM permissions, cost warnings |
| [01-project-a-cicd-ecs.md](01-project-a-cicd-ecs.md) | CI/CD with ECS Blue/Green Deployments |
| [02-project-b-config-remediation.md](02-project-b-config-remediation.md) | IaC & Config Remediation |
| [03-project-c-multiregion.md](03-project-c-multiregion.md) | Multi-Region with Route 53 & DynamoDB |
| [04-project-d-observability.md](04-project-d-observability.md) | Observability with CloudWatch |
| [05-project-e-incident-response.md](05-project-e-incident-response.md) | Incident Response with SSM |
| [06-project-f-governance.md](06-project-f-governance.md) | Governance & Multi-Account |
| [07-project-g-additional.md](07-project-g-additional.md) | Additional Topics (Image Builder, SAM, Service Catalog) |
| [08-teardown.md](08-teardown.md) | Complete teardown procedures |
| [09-troubleshooting.md](09-troubleshooting.md) | Common issues and solutions |
| [10-exam-tips.md](10-exam-tips.md) | Cost management and exam preparation |

---

## Recommended Order

The projects are designed to be completed in order (A → G) as some concepts build on previous knowledge. However, each project is self-contained and can be deployed independently.

## Time Estimates

| Project | Setup Time | Validation Time | Teardown Time |
|---------|------------|-----------------|---------------|
| A | 45-60 min | 30-45 min | 15-20 min |
| B | 30-45 min | 20-30 min | 10-15 min |
| C | 45-60 min | 30-45 min | 15-20 min |
| D | 30-45 min | 20-30 min | 10-15 min |
| E | 30-45 min | 20-30 min | 10-15 min |
| F | 60-90 min | 30-45 min | 20-30 min |
| G | 45-60 min | 30-45 min | 15-20 min |

## Exam Domain Mapping

| Project | Primary Exam Domain |
|---------|---------------------|
| A | Domain 1: SDLC Automation |
| B | Domain 2: Configuration Management & IaC |
| C | Domain 5: High Availability, Fault Tolerance, DR |
| D | Domain 3: Monitoring & Logging |
| E | Domain 4: Incident & Event Response |
| F | Domain 6: Policies & Standards Automation |
| G | Domains 1, 2, 6 (Additional Topics) |

## Quick Start

```bash
# Start with prerequisites
cat docs/guides/00-prerequisites.md

# Then work through each project
cat docs/guides/01-project-a-cicd-ecs.md
# ... and so on
```

---

**Good luck with your AWS DevOps Professional exam preparation!**
