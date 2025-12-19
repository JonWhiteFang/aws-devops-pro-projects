# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- `backend.hcl.example` — Shared backend configuration template
- `CONTRIBUTING.md` — Contribution guidelines
- `docs/cost-management.md` — Cost optimization strategies
- `docs/quick-reference.md` — Common commands and patterns
- `docs/faq.md` — Frequently asked questions
- `docs/security-considerations.md` — Security best practices
- `docs/extending-projects.md` — Customization guide
- `.terraform-docs.yml` — Terraform docs configuration
- Project G standard files (backend.tf, providers.tf, variables.tf, outputs.tf)

### Changed
- All `providers.tf` now include `required_version = ">= 1.5.0"`
- Projects D and E now use `var.region` instead of hardcoded region
- All `backend.tf` files now use shared config via `-backend-config`
- Updated `.tflint.hcl` plugin version to 0.36.0
- Updated GitHub Actions to include Project G subprojects
- Project B and F now have separate variables.tf and outputs.tf files
- Service Catalog `developer_role` is now configurable

### Fixed
- Consistent Terraform version constraints across all projects
- Standardized project structure for Project G subprojects

## [1.0.0] - 2025-12-17

### Added
- Initial release with seven projects (A-G)
- Project A: CI/CD with ECS Blue/Green deployments
- Project B: AWS Config rules and auto-remediation
- Project C: Multi-region with Route 53 and DynamoDB Global Tables
- Project D: CloudWatch observability stack
- Project E: SSM Automation incident response
- Project F: Governance with Security Hub, GuardDuty, CloudTrail
- Project G: Image Builder, SAM Lambda, Service Catalog
- Documentation: architecture diagrams, exam mapping, guides
- Pre-commit hooks and GitHub Actions validation
