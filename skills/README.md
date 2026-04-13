# Element AMS Skills

**AI-Optimized Skill Taxonomy** for Element AMS managed package development following skill-creator best practices.

## Overview

This directory contains 16 specialized skills organized into **8 core consolidated skills** and **8 Element-specific preserved skills** that guide AI agents through Element AMS development.

---

## 📚 Core Skills (8)

### 1. salesforce-architecture
**Architectural authority and decision-making framework**

- Package-first mindset for ISV managed packages
- Force-app directory structure (apex-common, selector, services, trigger, ui, base, data-processor)
- Separation of concerns (fflib layers)
- Security model, performance, quality gates
- Resolves conflicts between patterns

**Use when**: Making architectural decisions, designing features, reviewing code, understanding Element structure

---

### 2. apex-development
**Apex coding standards and patterns**

- Naming conventions, code templates
- Bulkification (200+ records minimum)
- Error handling, security (CRUD/FLS)
- Governor limits management
- **References apex-data-processor** for Element async patterns
- ApexDoc standards

**Use when**: Writing Apex, implementing business logic, applying security practices

---

### 3. apex-trigger-framework
**Metadata Trigger Action Framework**

- One trigger per object pattern
- TriggerAction interfaces (BeforeInsert, AfterUpdate, etc.)
- Custom metadata configuration (`Trigger_Action__mdt`)
- Execution order strategy
- Service integration, bypass mechanisms

**Use when**: Creating triggers, adding trigger logic, configuring metadata actions

---

### 4. apex-testing
**Comprehensive testing with ApexMocks**

- Three-tier test structure:
  - **Mock tests**: `force-app/<layer>/test/` (85%+ per class)
  - **DML tests**: `unpackaged/test_config/test_classes/service_test/` (global methods)
  - **Schema tests**: `unpackaged/test_config/test_classes/schema_test/` (field validation)
- ApexMocks framework
- Bulk testing (200+ records)

**Use when**: Writing tests, achieving coverage, testing async operations

---

### 5. lwc-development
**Lightning Web Component patterns**

- Property decorators (@api, @wire, @track)
- Event communication (parent-child, sibling via LMS)
- Lightning Data Service (LDS)
- SLDS design system
- **Integrates with frontend-design** for premium UI

**Use when**: Building LWC components, handling events, styling with SLDS

---

### 6. packaging-isvforce
**Second-generation packaging (2GP)**

- Namespace management (`element`)
- Version creation/promotion
- Backward compatibility
- AppExchange preparation
- sfdx-project.json configuration

**Use when**: Creating package versions, managing dependencies, preparing for AppExchange

---

### 7. cumulusci-devops
**CumulusCI automation patterns**

- Element-specific flows (dev_org, deploy_network)
- Snowfakery data recipes
- Scratch org management
- CI/CD integration

**Use when**: Setting up dev orgs, deploying metadata,loading test data, configuring CI/CD

---

### 8. pr-review-validation
**Code review checklist**

- Architectural pattern validation
- Security compliance
- Test coverage requirements
- Element-specific standards
- Quick validation gates

**Use when**: Reviewing PRs, validating code quality, ensuring compliance

---

## 🎯 Element-Specific Skills (8 - Preserved)

### apex-selector-pattern
**fflib Selector pattern for data access**

- Extends `fflib_SObjectSelector`
- SOQL encapsulation
- Security models (inherited sharing)
- Bulkification patterns

**Location**: `force-app/selector/`

---

### apex-service-pattern
**fflib Service pattern for business logic**

- Singleton pattern
- UnitOfWork for DML
- System mode documentation
- Service-Selector-Domain interactions

**Location**: `force-app/services/`

---

### apex-data-processor
**Element async pattern for scheduled operations**

- DataProcessor base classes
- Batch processing for complex transformations
- Referenced by apex-development for async patterns
- Element-specific conventions

**Location**: `force-app/data-processor/`

---

### logger-framework
**Nebula Logger integration**

- Logging standards
- Error tracking
- Element-specific conventions

**Location**: `force-app/logger/`

---

### metadata-configuration
**Element Custom Metadata Types**

- Trigger_Action__mdt configuration
- sObject_Trigger_Setting__mdt
- Community_Setting__mdt
- Element-specific metadata patterns

---

### experience-cloud-configuration
**Guest user patterns and communities**

- Platform Event pattern for guest DML
- Multi-community support
- Security models
- Element network configuration

**Location**: `unpackaged/config/networks/`

---

### frontend-design
**UI/UX excellence for LWC**

- Design thinking principles
- Premium aesthetics
- Avoiding generic AI patterns
- Production-grade interfaces

---

## 🔄 Skill Interaction Model

```
salesforce-architecture (Architectural Authority)
        |
        ├─→ apex-development ──→ apex-data-processor (async)
        ├─→ apex-trigger-framework ──→ metadata-configuration
        ├─→ apex-testing (tests all skills)
        ├─→ lwc-development ──→ frontend-design
        ├─→ packaging-isvforce
        ├─→ cumulusci-devops
        └─→ pr-review-validation ──→ (references all)

Preserved fflib Patterns:
        ├─→ apex-selector-pattern
        ├─→ apex-service-pattern

Element-Specific:
        ├─→ experience-cloud-configuration
        └─→ logger-framework
```

## 📋 Usage Workflow

### New Feature Development
1. **salesforce-architecture** - Understand approach & structure
2. **Choose layer skill** - apex-development, lwc-development, etc.
3. **apex-testing** - Write tests (85%+ coverage)
4. **pr-review-validation** - Validate before PR
5. **packaging-isvforce** - Deploy as package version

### Code Review
1. **pr-review-validation** - Quick checklist
2. **salesforce-architecture** - Verify patterns
3. **Specific skill** - Detailed validation

### Troubleshooting
1. Identify component layer (selector, service, trigger, LWC)
2. Consult relevant skill
3. Cross-reference with salesforce-architecture

---

## 🎯 Quick Reference

| Task | Primary Skill | Supporting Skills |
|------|---------------|-------------------|
| **Write SOQL** | apex-selector-pattern | salesforce-architecture |
| **Business logic** | apex-service-pattern | apex-development |
| **Triggers** | apex-trigger-framework | metadata-configuration |
| **Testing** | apex-testing | All implementation skills |
| **Async processing** | apex-data-processor | apex-development |
| **UI components** | lwc-development | frontend-design |
| **Package version** | packaging-isvforce | cumulusci-devops |
| **Guest user DML** | experience-cloud-configuration | salesforce-architecture |
| **Code review** | pr-review-validation | salesforce-architecture |
| **Dev org setup** | cumulusci-devops | salesforce-architecture |

---

## 📊 Skill Statistics

- **Total Skills**: 16
- **Core Skills**: 8 (~3,150 lines total)
- **Element-Specific**: 8 (preserved patterns)
- **Average Skill Size**: 300-560 lines
- **Documentation Coverage**: 100%

---

## ✨ Design Principles

### Conciseness
- Target: 300-550 lines per skill
- Focus on Element-specific knowledge
- Prefer examples over verbose explanations

### Progressive Disclosure
- Name + description always visible
- Full content loaded only when skill triggers
- Quick reference tables for rapid lookup

### Clear Interactions
- Each skill documents dependencies
- Cross-references to related skills
- Decision flows clearly articulated

### Element-Specific
- ISV managed package patterns
- Namespace awareness
- Backward compatibility
- AppExchange compliance

---

## 🚀 Success Criteria

✅ **Comprehensive Coverage** - All Element patterns documented  
✅ **Progressive Disclosure** - Concise without sacrificing clarity  
✅ **Clear Interactions** - Dependencies well-defined  
✅ **Element Patterns Preserved** - User feedback incorporated  
✅ **AI-Optimized** - Skill-creator guidelines followed  
✅ **Package-First** - ISV best practices throughout

---

**Version**: 2.0  
**Last Updated**: 2026-01-30  
**Maintained By**: Element AMS Team  
**License**: See LICENSE.txt
