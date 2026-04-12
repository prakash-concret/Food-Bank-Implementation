---
name: cumulusci-devops
description: CumulusCI automation and DevOps workflows for Element AMS. Use when creating deployment flows, managing scratch orgs, automating tests, running Element-specific flows (dev_org, deploy_network), or configuring CI/CD pipelines. Focuses on Element automation patterns and Snowfakery data recipes.
---

# CumulusCI DevOps

## Purpose

Automate **Element AMS development, testing, and deployment** using CumulusCI workflows and Salesforce DX, focusing on Element-specific automation patterns.

## When to Use

- Setting up development orgs
- Deploying Element metadata
- Running automated tests
- Loading test data with Snowfakery
- Configuring CI/CD pipelines

## Common Commands

```bash
# Create scratch org
cci org scratch dev dev

# Deploy Element
cci task run deploy --org dev

# Run full dev setup flow
cci flow run dev_org --org dev

# Run tests
cci task run run_tests --org dev

# Open org in browser
cci org browser dev

# Delete org
cci org scratch_delete dev
```

## Element-Specific Flows

### Development Org Setup

```yaml
# cumulusci.yml
dev_org:
    description: Setup complete development environment
    steps:
        1:
            flow: deploy_network          # Deploy Experience Cloud
        2:
            task: assign_permission_sets  # Assign permissions
        3:
            task: snowfakery              # Load test data
                options:
                    recipe: datasets/dev/snowfakery.mapping.yml
        4:
            flow: schedule_async_jobs     # Schedule processors
```

### Network Deployment

```yaml
deploy_network:
    description: Deploy and publish Experience Cloud sites
    steps:
        1:
            task: custom_deploy
        2:
            task: deploy_metadata
        3:
            task: publish_community
```

### Scheduled Jobs Setup

```yaml
schedule_async_jobs:
    description: Schedule Element data processors
    steps:
        1:
            flow: schedule_auto_renew_membership
        2:
            flow: schedule_automatic_payments
        3:
            flow: schedule_auto_update_segment
```

## Snowfakery Data Recipes

### Test Data Pattern

```yaml
# datasets/dev/snowfakery.mapping.yml
- object: Account
  count: 10
  fields:
    Name:
      fake: company
    BillingCity:
      random_choice:
        - San Francisco
        - New York
        - Chicago

- object: Contact
  count: 50
  fields:
    FirstName:
      fake: first_name
    LastName:
      fake: last_name
    Email:
      fake: email
    AccountId:
      reference: Account

- object: element__Product__c
  count: 5
  fields:
    Name:
      fake: 
        - Annual Membership
        - Monthly Membership
        - Premium Membership
    Price__c:
      random_number:
        min: 100
        max: 1000

- object: element__Membership__c
  count: 100
  fields:
    Name:
      fake: sentence
    Contact__c:
      reference:Contact
    Product__c:
      reference: element__Product__c
    Start_Date__c:
      date_between:
        start_date: -1y
        end_date: today
    End_Date__c:
      date_between:
        start_date: today
        end_date: +1y
    Status__c:
      random_choice:
        - Active
        - Expired
        - Pending
```

## CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/ci.yml
name: CI
on: [pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install CumulusCI
        run: pip install cumulusci
      
      - name: Auth Dev Hub
        env:
          SFDX_AUTH_URL: ${{ secrets.SFDX_AUTH_URL }}
        run: |
          echo $SFDX_AUTH_URL > sfdx_auth
          cci org connect devhub --service sfdx

      - name: Run Tests
        run: cci flow run ci_test --org scratch
```

## Custom Tasks

Located in `tasks/` directory:

```python
# tasks/custom_deploy.py
from cumulusci.tasks.salesforce import BaseSalesforceApiTask

class CustomDeploy(BaseSalesforceApiTask):
    task_options = {
        "path": {"description": "Path to deploy"},
    }

    def _run_task(self):
        path = self.options["path"]
        # Custom deployment logic
        self.logger.info(f"Deploying {path}")
```

## Org Definitions

```json
// orgs/dev.json
{
  "edition": "Developer",
  "settings": {
    "lightningExperienceSettings": {
      "enableS1DesktopEnabled": true
    },
    "communitiesSettings": {
      "enableNetworksEnabled": true
    }
  }
}
```

## Testing Flows

```yaml
ci_test:
    description: Run all tests for CI
    steps:
        1:
            task: deploy
        2:
            task: run_tests
                options:
                    required_per_class_code_coverage_percent: 85
```

## Do's and Don'ts

### ✅ DO

- Use flows for repetitive sequences
- Version control `cumulusci.yml`
- Use Snowfakery for test data
- Automate org setup
- Test flows locally before CI
- Document custom tasks

### ❌ DON'T

- Hardcode org credentials
- Skip error handling in custom tasks
- Create overly complex flows
- Commit auth files (`.sfdx`, `*.key`)
- Mix packaging tasks here (see `packaging-isvforce`)

## Element Conventions

1. **Dev Flow**: `dev_org` sets up complete environment
2. **Test Data**: Snowfakery recipes in `datasets/`
3. **Network Deploy**: Automated community deployment
4. **Async Jobs**: Scheduled via flows

## Interactions with Other Skills

### Used By
- **packaging-isvforce** - Package deployment automation
- **salesforce-architecture** - Org setup and deployment

### References
- **apex-testing** - Test execution
- **experience-cloud-configuration** - Community deployment

## Quick Reference

| Task | Command |
|------|---------|
| Setup dev org | `cci flow run dev_org --org dev` |
| Deploy metadata | `cci task run deploy --org dev` |
| Run tests | `cci task run run_tests --org dev` |
| Load data | `cci task run snowfakery --recipe datasets/dev/snowfakery.mapping.yml` |
| Open org | `cci org browser dev` |
