---
inclusion: always
---

# Product Overview

AWS DevOps Pro: Seven hands-on Terraform projects aligned to AWS DevOps Engineer Professional exam domains.

## Project Mapping

| Project | Focus Area | Exam Domain |
|---------|------------|-------------|
| A | CI/CD with ECS blue/green deployments | SDLC Automation (22%) |
| B | AWS Config rules + auto-remediation | Configuration Management & IaC (17%) |
| C | Multi-region HA with Route 53 + DynamoDB Global Tables | HA, Fault Tolerance, DR (18%) |
| D | CloudWatch dashboards, alarms, Synthetics, X-Ray | Monitoring & Logging (15%) |
| E | SSM Automation runbooks | Incident & Event Response (15%) |
| F | SCPs, Security Hub, GuardDuty, Organizations | Policies & Standards (13%) |
| G | Image Builder, SAM Lambda, Service Catalog | SDLC + Config Management |

## AI Assistant Guidelines

When working in this repository:

1. **Maintain exam alignment** - All code should demonstrate patterns relevant to AWS DevOps Professional certification
2. **Prioritize deployability** - Code must be ready-to-deploy with minimal configuration (copy tfvars.example, init, apply)
3. **Use realistic patterns** - Implement production-grade configurations, not simplified demos
4. **Document for learning** - READMEs should explain the "why" behind architectural decisions, not just "how"
5. **Cross-reference domains** - When modifying code, consider which exam domains it covers and maintain that alignment

## Content Principles

- Examples should be self-contained within each project folder
- Prefer AWS-native services over third-party alternatives
- Include cost considerations in documentation
- Provide cleanup instructions to avoid unexpected charges
