# TODO — Repository Issues

**Generated:** 2025-12-19
**Status:** ✅ ALL ITEMS COMPLETED

---

## Medium Priority

### 1. ~~Missing `required_version` in providers.tf~~ ✅ FIXED

Added `required_version = ">= 1.5.0"` to the `terraform` block.

**Fixed files:**
- [x] `project-b-iac-config-remediation/infra-terraform/providers.tf`
- [x] `project-c-multiregion-route53-dynamodb/infra-terraform/providers.tf`
- [x] `project-d-observability-cloudwatch/infra-terraform/providers.tf`
- [x] `project-e-incident-response-ssm/infra-terraform/providers.tf`
- [x] `project-f-governance-multiaccount/infra-terraform/providers.tf`

### 2. ~~Hardcoded Region in Providers~~ ✅ FIXED

Replaced `region = "eu-west-1"` with `region = var.region`.

**Fixed files:**
- [x] `project-d-observability-cloudwatch/infra-terraform/providers.tf`
- [x] `project-e-incident-response-ssm/infra-terraform/providers.tf`

---

## Low Priority

### 3. ~~Missing Standard File Separation (Project B)~~ ✅ FIXED

Extracted inline definitions to separate files.

- [x] Created `project-b-iac-config-remediation/infra-terraform/variables.tf`
- [x] Created `project-b-iac-config-remediation/infra-terraform/outputs.tf`

### 4. ~~Missing Standard File Separation (Project F)~~ ✅ FIXED

- [x] Created `project-f-governance-multiaccount/infra-terraform/variables.tf`
- [x] Created `project-f-governance-multiaccount/infra-terraform/outputs.tf`

### 5. ~~Project G Subprojects Missing Standard Files~~ ✅ FIXED

Created all standard files for Project G subprojects:
- [x] `project-g-additional-topics/image-builder/backend.tf`
- [x] `project-g-additional-topics/image-builder/providers.tf`
- [x] `project-g-additional-topics/image-builder/variables.tf`
- [x] `project-g-additional-topics/image-builder/outputs.tf`
- [x] `project-g-additional-topics/image-builder/terraform.tfvars.example`
- [x] `project-g-additional-topics/service-catalog/backend.tf`
- [x] `project-g-additional-topics/service-catalog/providers.tf`
- [x] `project-g-additional-topics/service-catalog/variables.tf`
- [x] `project-g-additional-topics/service-catalog/outputs.tf`
- [x] `project-g-additional-topics/service-catalog/terraform.tfvars.example`

### 6. ~~GitHub Actions Missing Project G Validation~~ ✅ FIXED

Added Project G subprojects to `.github/workflows/validate.yml` matrix:
- [x] `project-g-additional-topics/image-builder`
- [x] `project-g-additional-topics/service-catalog`

### 7. ~~Missing `.terraform-docs.yml`~~ ✅ FIXED

- [x] Created `.terraform-docs.yml`

### 8. ~~TFLint Plugin Version Outdated~~ ✅ FIXED

- [x] Updated `.tflint.hcl` plugin version from `0.27.0` to `0.36.0`

---

## Info / Documentation

### 9. ~~Hardcoded Account ID in Backend Configurations~~ ✅ FIXED

Created `backend.hcl.example` at repo root. All `backend.tf` files now only contain the state key and reference the shared config via `-backend-config=../../backend.hcl`.

### 10. ~~Service Catalog Assumes DeveloperRole Exists~~ ✅ FIXED

Made `developer_role` configurable via variable with default value `DeveloperRole`. Added comment noting the role must exist before applying.

---

## Summary

All issues have been resolved. The repository now follows consistent patterns across all projects.
