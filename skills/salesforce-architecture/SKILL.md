---
name: salesforce-architecture
description: Overall architectural authority and decision-making framework for Element AMS ISV package. Use when making architectural decisions, designing system structure, reviewing patterns, resolving conflicts between approaches, or understanding Element's force-app directory structure and separation of concerns. Covers package-first mindset, fflib layers, security model, and quality gates.
---

# Salesforce Architecture

## Purpose

Provides **architectural authority** for Element AMS, a Salesforce ISV managed package (2GP). This skill defines the package-first mindset, separation of concerns, directory structure, and quality gates that guide all development decisions.

## When to Use

- Designing new features or components
- Resolving conflicts between different patterns
- Making architectural trade-offs
- Reviewing code for architectural compliance
- Understanding Element's package structure

## Package-First Mindset

Element is a **managed package** distributed through AppExchange. Every decision must consider:

1. **Namespace awareness** (`element__`) - No hardcoded field names
2. **Subscriber compatibility** - Backward compatibility required
3. **Installation constraints** - Works in any org configuration
4. **Security Review** - AppExchange compliance mandatory

## Force-App Directory Structure

Element respects the following **subfolder organization**:

```
force-app/
├── apex-common/          # fflib framework base classes
├── selector/             # Data access layer (Selectors)
│   ├── main/classes/
│   └── test/classes/
├── services/             # Business logic orchestration
│   ├── main/classes/
│   └── test/classes/
├── trigger/              # Trigger framework
│   ├── main/classes/     # Trigger action classes
│   └── test/classes/
├── trigger-framework/    # MetadataTriggerHandler core
├── data-processor/       # Async operations (Element-specific)
│   ├── main/classes/
│   └── test/classes/
├── ui/                   # Lightning Web Components
│   ├── lwc/
│   └── controller/       # LWC Apex controllers
├── base/                 # Metadata (objects, fields, tabs, etc.)
│   ├── objects/
│   ├── triggers/
│   └── layouts/
└── logger/               # Nebula Logger integration

unpackaged/              # Unmanaged extensions
├── config/              # Org-specific configuration
└── test_config/         # DML and schema tests
    └── test_classes/
        ├── service_test/      # DML tests for global methods
        ├── trigger_test/      # DML tests for trigger actions
        └── schema_test/       # Field validation tests
```

> [!IMPORTANT]
> **Respect this structure** - Do not create new top-level folders without architectural review.

## Separation of Concerns (fflib Layers)

Element follows **fflib architecture** for clean separation:

```
┌─────────────────────────────────────────────┐
│              UI Layer (LWC)                 │
│         force-app/ui/lwc/                   │
└──────────────────┬──────────────────────────┘
                   │ @AuraEnabled
┌──────────────────▼──────────────────────────┐
│         Controllers (Apex)                  │
│      force-app/ui/controller/               │
└──────────────────┬──────────────────────────┘
                   │ delegates to
┌──────────────────▼──────────────────────────┐
│      Services (Business Logic)              │
│       force-app/services/                   │
└──────────────────┬──────────────────────────┘
           ┌───────┴───────┐
           │               │
┌──────────▼─────┐  ┌──────▼──────────────────┐
│   Selectors    │  │  Data Processors        │
│  (SOQL only)   │  │  (Async operations)     │
│ force-app/     │  │  force-app/             │
│  selector/     │  │  data-processor/        │
└────────────────┘  └─────────────────────────┘
```

### Layer Responsibilities

| Layer | Purpose | Location | Key Rules |
|-------|---------|----------|-----------|
| **LWC** | UI presentation | `force-app/ui/lwc/` | No business logic, no SOQL/DML |
| **Controllers** | LWC-Apex bridge | `force-app/ui/controller/` | Delegate to Services, `with sharing` |
| **Services** | Business logic | `force-app/services/` | No SOQL/DML directly, use Selectors & UoW |
| **Selectors** | Data access | `force-app/selector/` | SOQL only, extends `fflib_SObjectSelector` |
| **Data Processors** | Async operations | `force-app/data-processor/` | Scheduled jobs, complex transformations |
| **Trigger Actions** | Event handlers | `force-app/trigger/` | Implements `TriggerAction` interfaces |

## Key Architectural Patterns

### 1. Selectors for Data Access

**Use:** `apex-selector-pattern` skill

```apex
// CORRECT - Use Selector
List<Account> accounts = AccountSelector.getInstance()
    .selectById(accountIds);

// WRONG - Direct SOQL in Service
List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id IN :ids];
```

### 2. Services for Business Logic

**Use:** `apex-service-pattern` skill

```apex
// CORRECT - Service coordinates logic
MembershipService.getInstance().renewMemberships(membershipIds);

// WRONG - Logic in Controller or Trigger
update memberships; // Use Service!
```

### 3. Triggers via Metadata Framework

**Use:** `apex-trigger-framework` skill

- **One trigger per object** - Delegates to `MetadataTriggerHandler`
- **Logic in Action classes** - Configured via `Trigger_Action__mdt`
- **Service integration** - Actions call Services for complex logic

### 4. Data Processors for Async

**Use:** `apex-data-processor` skill

- **Scheduled operations** - Batch processing, data cleanup
- **Complex transformations** - Multi-step async workflows
- **Reference from apex-development** - For general async patterns

## API Design Patterns

### Global Methods

**Use when:**
- Exposing functionality to subscribers
- Creating extensibility points
- Building managed package APIs

**Requirements:**
- Must maintain backward compatibility
- Require DML tests in `unpackaged/test_config/test_classes/service_test/`
- Document version introduced
- Use `@Deprecated` for obsolete methods

**Example:**
```apex
/**
 * @description Renew memberships
 * @param membershipIds IDs to renew
 * @return Map of membership ID to invoice ID
 * @since 1.5.0
 */
global static Map<Id, Id> renewMemberships(Set<Id> membershipIds) {
    return getInstance().renewMembershipsImpl(membershipIds);
}
```

## Security Model

### Default: Inherited Sharing

```apex
public inherited sharing class AccountSelector { }
```

### System Mode: Requires Documentation

```apex
/**
 * @FalsePositive - System mode required for admin dashboard aggregation
 * across all accounts. Users must have 'View_All_Accounts' permission.
 * Approved by Security team 2024-01-15. Ticket: SEC-12345
 */
public without sharing class ReportingService { }
```

### CRUD/FLS Enforcement

Use `fflib_SecurityUtils` for field-level security:

```apex
fflib_SecurityUtils.checkFieldIsReadable(
    Account.SObjectType,
    'AnnualRevenue'
);
```

## Performance Considerations

### Governor Limits

- **SOQL:** < 100 queries per transaction
- **DML:** < 150 statements (use UnitOfWork)
- **CPU:** < 10,000ms (use async for heavy processing)
- **Heap:** < 6MB synchronous, < 12MB async

### Bulkification

**Minimum test:** 200 records per operation

```apex
// CORRECT - Bulkified
Map<Id, Account> accountMap = new Map<Id, Account>(
    AccountSelector.getInstance().selectById(accountIds)
);

// WRONG - Queries in loop
for (Id accountId : accountIds) {
    Account acc = [SELECT Id FROM Account WHERE Id = :accountId];
}
```

### Platform Events for Guest Users

**Use:** `experience-cloud-configuration` skill

Guest users cannot perform DML directly - use Platform Events pattern.

## Quality Gates

### Before Code Commit

✅ Unit tests pass (mock tests co-located)  
✅ 90%+ code coverage per class  
✅ No SOQL in Services  
✅ No DML outside Services/UnitOfWork  
✅ ApexDoc on public methods  

### Before Package Version

✅ DML tests for global methods pass  
✅ Schema tests for new fields pass  
✅ 90%+ overall package coverage  
✅ PMD violations resolved  
✅ Security documentation complete  

## Anti-Patterns

### ❌ Wrong Layer

```apex
// WRONG - SOQL in Service
public class BadService {
    public List<Account> getAccounts() {
        return [SELECT Id FROM Account]; // Use Selector!
    }
}

// WRONG - Logic in Trigger
trigger BadTrigger on Account (before insert) {
    for (Account acc : Trigger.new) {
        acc.Name = 'Modified'; // Use Trigger Action!
    }
}
```

### ❌ Hardcoded Namespace

```apex
// WRONG
String fieldName = 'element__Account__c';

// CORRECT
SObjectField field = Account__c.SObjectType;
```

### ❌ Non-Bulkified Code

```apex
// WRONG - Queries in loop
for (Membership__c m : memberships) {
    Account acc = [SELECT Id FROM Account WHERE Id = :m.Account__c];
}

// CORRECT - Bulkified
Set<Id> accountIds = new Set<Id>();
for (Membership__c m : memberships) {
    accountIds.add(m.Account__c);
}
Map<Id, Account> accounts = new Map<Id, Account>(
    AccountSelector.getInstance().selectById(accountIds)
);
```

## Decision Framework

When making architectural decisions:

1. **Check existing patterns** - Is there an established Element pattern?
2. **Consult relevant skill** - apex-selector-pattern, apex-service-pattern, etc.
3. **Consider package constraints** - Namespace, backward compatibility
4. **Validate against quality gates** - Coverage, bulkification, security
5. **Document exceptions** - If deviating from patterns, document why

## Interactions with Other Skills

### Primary Authority
- All architectural decisions flow through this skill
- Resolves conflicts between patterns
- Defines structure and quality standards

### Delegates To
- **apex-selector-pattern** - Data access implementation
- **apex-service-pattern** - Business logic implementation
- **apex-trigger-framework** - Trigger architecture
- **apex-data-processor** - Async operations
- **lwc-development** - UI components
- **packaging-isvforce** - 2GP packaging
- **experience-cloud-configuration** - Guest user patterns

## Quick Reference

| Decision | Use Skill | Key Consideration |
|----------|-----------|-------------------|
| Where to put SOQL? | apex-selector-pattern | Always in Selector layer |
| Where to put business logic? | apex-service-pattern | Service layer, use UoW for DML |
| How to handle triggers? | apex-trigger-framework | MetadataTriggerHandler + action classes |
| How to do async processing? | apex-data-processor | DataProcessor pattern for Element |
| Guest user DML? | experience-cloud-configuration | Use Platform Events |
| Making method global? | packaging-isvforce | Requires DML tests, version docs |
