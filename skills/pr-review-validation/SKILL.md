---
name: pr-review-validation
description: Code review framework for Element AMS pull requests. Detects changed file types, loads the relevant @skills/ files for each type, and applies their exact rules to give accurate, context-specific feedback. Covers Selectors, Services, Trigger Actions, Data Processors, LWC, Jest tests, Apex tests, metadata, and package compliance.
---

# PR Review Validation

## Purpose

Intelligent **PR review framework** for Element AMS. It detects what types of files changed, reads the corresponding skill files for those types, and applies their exact rules — giving precise, skill-grounded feedback rather than generic checks.

---

## Review Process (Follow Every Step in Order)

### Step 1 — Identify Changed Files

Run this command to get the list of files changed in the PR:

```bash
gh pr diff <PR_NUMBER> --repo <REPO> --name-only
```

Or, if you already have the PR context, inspect the diff to list all added/modified files.

---

### Step 2 — Map Files to Skill Files and Read Them

For every changed file, find its matching row(s) in the table below and **read each listed skill file** using the `Read` tool before reviewing any code. Do not skip this step — the skill files contain the authoritative rules.

| If PR contains files matching… | Read these skill files |
|---|---|
| `force-app/selector/**/*.cls` | `skills/apex-selector-pattern/SKILL.md` + `skills/apex-development/SKILL.md` |
| `force-app/services/**/*.cls` (non-test) | `skills/apex-service-pattern/SKILL.md` + `skills/apex-development/SKILL.md` |
| `force-app/services/test/**/*Test.cls` | `skills/apex-testing/SKILL.md` + `skills/apex-testing-mocking/SKILL.md` |
| `force-app/trigger/**/*.cls` | `skills/apex-trigger-framework/SKILL.md` + `skills/apex-development/SKILL.md` |
| `force-app/trigger-framework/**` | `skills/apex-trigger-framework/SKILL.md` |
| `force-app/base/**/*.trigger` or `*.trigger` | `skills/apex-trigger-framework/SKILL.md` |
| `force-app/data-processor/**/*.cls` | `skills/apex-data-processor/SKILL.md` + `skills/apex-development/SKILL.md` |
| `force-app/ui/lwc/**/*.html` or `*.js` or `*.css` | `skills/lwc-development/SKILL.md` |
| `force-app/ui/lwc/**/__tests__/*.test.js` | `skills/lwc-jest-testing/SKILL.md` |
| `force-app/ui/controller/**/*.cls` | `skills/lwc-controller-integration/SKILL.md` + `skills/apex-development/SKILL.md` |
| `force-app/logger/**` | `skills/logger-framework/SKILL.md` |
| `force-app/base/**` (objects, fields, layouts, metadata) | `skills/metadata-configuration/SKILL.md` + `skills/packaging-isvforce/SKILL.md` |
| `unpackaged/test_config/test_classes/service_test/**` | `skills/apex-testing/SKILL.md` |
| `unpackaged/test_config/test_classes/trigger_test/**` | `skills/apex-testing/SKILL.md` |
| `unpackaged/test_config/test_classes/schema_test/**` | `skills/apex-testing/SKILL.md` |
| Any Apex `.cls` file (catch-all) | `skills/apex-development/SKILL.md` |
| New directory, new layer, structural change | `skills/salesforce-architecture/SKILL.md` |
| Any `global` keyword in changed code | `skills/packaging-isvforce/SKILL.md` |

> **Multiple skills often apply to one file.** For example, a new `MembershipSelector.cls` in `force-app/selector/` requires both `apex-selector-pattern` (pattern rules) and `apex-development` (coding standards, PMD, ApexDoc).

---

### Step 3 — Review Each Changed File Using the Loaded Skills

After reading the skill files, review each changed file using:

1. **Skill-specific rules** from the files you loaded in Step 2 (highest priority — most precise)
2. **General checks** from the section below (apply to all files)

Only review code that was **actually changed** in this PR. Do not comment on unchanged lines.

---

### Step 4 — Post Findings as Inline PR Comments

Use `mcp__github_inline_comment__create_inline_comment` to post inline comments at the exact line where each issue appears. For file-level issues, post at the first changed line of the file.

---

## General Checks (Apply to All Apex Files)

These apply regardless of layer. Run them alongside the skill-specific checks.

### Security & Sharing

- [ ] `inherited sharing` is the default on all classes
- [ ] Any `without sharing` class has a `@FalsePositive` block comment explaining WHY, who approved it, and a ticket reference
- [ ] FLS/CRUD checked via `fflib_SecurityUtils` where user data is accessed

**See:** `skills/apex-development/SKILL.md` — Security Practices section

### Naming Conventions

| Class Type | Expected Pattern |
|---|---|
| Selector | `<SObject>Selector.cls` |
| Service | `<Function>Service.cls` |
| Trigger Action | `TA_<SObject>_<Operation>.cls` |
| Data Processor | `<Purpose>DataProcessor.cls` |
| Controller | `<Component>Controller.cls` |
| Test | `<ClassName>Test.cls` |

**See:** `skills/apex-development/SKILL.md` — Naming Conventions section

### Documentation

- [ ] ApexDoc present on all public/global methods (`@description`, `@param`, `@return`)
- [ ] Inline comments explain WHY for complex logic (not just what)
- [ ] System mode (`without sharing`) documented with `@FalsePositive`

### Package Compliance

- [ ] No hardcoded namespace strings (`element__`)
- [ ] `Schema.SObjectField` references used instead of string field names
- [ ] No hardcoded org-specific IDs
- [ ] Global methods not modified in a breaking way
- [ ] Deprecated methods marked `@Deprecated` with version and replacement documented

**See:** `skills/packaging-isvforce/SKILL.md`

### Performance (Governor Limits)

- [ ] No SOQL queries inside loops
- [ ] No DML inside loops
- [ ] UnitOfWork used for all DML operations
- [ ] Query count stays under 100 per transaction
- [ ] DML count stays under 150 per transaction

**See:** `skills/salesforce-architecture/SKILL.md` — Performance Considerations section

### PMD Static Analysis Rules (Apex Only)

- [ ] **ExcessiveParameterList**: No method has more than 3 parameters — wrap extras in a request/DTO inner class
- [ ] **CyclomaticComplexity**: No method exceeds complexity of 10 — extract named private helpers

**See:** `skills/apex-development/SKILL.md` — PMD Code Quality Rules section

---

## Skill-Specific Review Checklists

Use these as a quick reference *after* reading the full skill files loaded in Step 2. The skill files contain examples, patterns, and anti-patterns not repeated here.

### Selectors (`force-app/selector/**`)

*Loaded skill:* `skills/apex-selector-pattern/SKILL.md`

- [ ] Extends `fflib_SObjectSelector`
- [ ] `getSObjectType()` and `getSObjectFieldList()` implemented
- [ ] Singleton: `getInstance()` + `@TestVisible setInstance()`
- [ ] All dynamic queries use `newQueryFactory()` — no raw SOQL strings
- [ ] Query methods named `selectBy<Criteria>()`
- [ ] Uses `Schema.SObjectField` references (not hardcoded string field names)
- [ ] No DML operations anywhere in the class
- [ ] Bind variables used in all SOQL conditions (no string concatenation)
- [ ] Located in `force-app/selector/main/classes/`

### Services (`force-app/services/**`)

*Loaded skill:* `skills/apex-service-pattern/SKILL.md`

- [ ] No direct SOQL — all queries delegated to Selectors
- [ ] No direct DML — all writes go through UnitOfWork
- [ ] Singleton: `getInstance()` + `@TestVisible setInstance()`
- [ ] Business logic does not leak into Trigger Actions or Controllers
- [ ] Complex operations broken into private helper methods (cyclomatic complexity ≤ 10)
- [ ] Errors caught, logged via Logger, then rethrown with meaningful message

### Trigger Actions (`force-app/trigger/**`, `*.trigger`)

*Loaded skill:* `skills/apex-trigger-framework/SKILL.md`

- [ ] Trigger file body is ONLY `new MetadataTriggerHandler().run();` — no logic
- [ ] Action class implements correct `TriggerAction.*` interface(s)
- [ ] Action class named `TA_<SObject>_<Operation>`
- [ ] Complex logic delegated to a Service (actions are thin coordinators)
- [ ] Action configured in `Trigger_Action__mdt` with correct `Order__c`
- [ ] Handles bulk (200+ records) — no per-record SOQL/DML
- [ ] DML test exists in `unpackaged/test_config/test_classes/trigger_test/`

### Data Processors (`force-app/data-processor/**`)

*Loaded skill:* `skills/apex-data-processor/SKILL.md`

- [ ] Extends `DataProcessor` base class
- [ ] `start()`, `execute()`, `finish()` implemented correctly
- [ ] Business logic delegated to Service — no complex logic in `execute()`
- [ ] No DML directly in processor (uses Service with UoW)
- [ ] Error handling: try/catch with Logger, does NOT rethrow (allows batch to continue)
- [ ] Handles large volumes (default batch size 200 or explicit override)
- [ ] Located in `force-app/data-processor/main/classes/`

### LWC Components (`force-app/ui/lwc/**/*.html`, `*.js`, `*.css`)

*Loaded skill:* `skills/lwc-development/SKILL.md`

- [ ] No underscore-prefixed variables (`_value` → `valueInternal`)
- [ ] Every interactive/meaningful HTML element has a unique `data-id` (kebab-case)
- [ ] No `document.querySelector` or jQuery
- [ ] Errors surfaced via Toast events (not `console.error`)
- [ ] SLDS utility classes used for layout and spacing
- [ ] Sibling communication uses Lightning Message Service (not shared state)
- [ ] Apex calls done in controller layer, not directly in component (unless wire)
- [ ] Accessibility: ARIA labels present, keyboard navigation supported

### LWC Jest Tests (`force-app/ui/lwc/**/__tests__/*.test.js`)

*Loaded skill:* `skills/lwc-jest-testing/SKILL.md`

- [ ] Uses `createComponent` helper — `@api` props set **before** `appendChild`
- [ ] All DOM queries use `[data-id="..."]` (not class or tag selectors)
- [ ] `await flushPromises()` called before any DOM assertions
- [ ] `afterEach` drains `document.body` and calls `jest.clearAllMocks()`
- [ ] All `@salesforce/*` imports mocked with `{ virtual: true }`
- [ ] Form-factor-specific tests split into `LargeDevice.test.js` / `SmallDevice.test.js`
- [ ] Events: listener attached before `flushPromises`, dispatched from inside `shadowRoot`

### Apex Mock Tests (co-located `*Test.cls` in `force-app/`)

*Loaded skills:* `skills/apex-testing/SKILL.md` + `skills/apex-testing-mocking/SKILL.md`

- [ ] Selector mocks use `MockApexClasses.mock<SObjectName>Selector()` — never inlined for happy-path
- [ ] Service mocks assigned directly to `@TestVisible` static field
- [ ] Full selector chain stubbed (`selectFields`, `setCondition`, `setLimit`, `setOrdering`, `getData`)
- [ ] Roll-up/formula fields set via `fflib_ApexMocksUtils.setReadOnlyFields` (not direct assignment)
- [ ] `mocks.startStubbing()` / `mocks.stopStubbing()` wraps all stub setup
- [ ] Positive AND negative scenarios both tested
- [ ] Bulk tested with 200+ records
- [ ] Coverage: 85%+ per class

### DML Tests (`unpackaged/test_config/test_classes/service_test/`, `trigger_test/`)

*Loaded skill:* `skills/apex-testing/SKILL.md`

- [ ] Uses real DML (no ApexMocks)
- [ ] Covers every `global` method end-to-end
- [ ] Bulk tested with 200 records
- [ ] Located in correct folder (`service_test/` for services, `trigger_test/` for trigger actions)

### Schema Tests (`unpackaged/test_config/test_classes/schema_test/`)

*Loaded skill:* `skills/apex-testing/SKILL.md`

- [ ] Validates all picklist field values match expected set
- [ ] Validates required fields throw `DmlException` when empty
- [ ] Validates field length constraints
- [ ] One schema test file per SObject with new fields

### Apex Controllers (`force-app/ui/controller/**`)

*Loaded skill:* `skills/lwc-controller-integration/SKILL.md` + `skills/apex-development/SKILL.md`

- [ ] Uses `with sharing` (controllers serve UI — always apply sharing rules)
- [ ] All `@AuraEnabled` methods delegate to a Service — no business logic in controller
- [ ] Catches exceptions and rethrows as `AuraHandledException`
- [ ] No direct SOQL or DML

### Metadata & Fields (`force-app/base/**`)

*Loaded skills:* `skills/metadata-configuration/SKILL.md` + `skills/packaging-isvforce/SKILL.md`

- [ ] New custom fields have a corresponding schema test in `unpackaged/test_config/test_classes/schema_test/`
- [ ] Configurable values use Custom Metadata (not hardcoded in Apex)
- [ ] No sensitive data in metadata field defaults

---

## Common Anti-Patterns to Reject

```apex
// ❌ SOQL directly in Service
public class BadService {
    public List<Account> getAccounts() {
        return [SELECT Id FROM Account]; // Use AccountSelector!
    }
}

// ❌ DML without UnitOfWork
public class BadService {
    public void save(Account acc) {
        update acc; // Use UnitOfWork!
    }
}

// ❌ Logic in trigger body
trigger BadTrigger on Account (before insert) {
    for (Account acc : Trigger.new) {
        acc.Name = 'Modified'; // Move to TA_Account_SetName!
    }
}

// ❌ Hardcoded namespace
String field = 'element__Account__c'; // Use Account.SObjectType schema ref!

// ❌ system mode with no documentation
public without sharing class BadClass {
    // Missing @FalsePositive comment!
}

// ❌ PMD: too many parameters
public void create(Id a, String b, Date c, Decimal d) { }
// Use a request inner class instead

// ❌ LWC: underscore prefix
_value = 0; // Use valueInternal!

// ❌ LWC: missing data-id
<lightning-button label="Save" onclick={handleSave}></lightning-button>
// Must add data-id="save-button"

// ❌ Inline selector chain stub in test (happy-path)
mocks.when(mySelector.selectFields(fflib_Match.anyObject())).thenReturn(mySelector);
// Use MockApexClasses.mockMySelector(mocks, dataList)!
```

---

## Output Format

For each issue found, post an inline comment with:

1. **Problem**: What exactly is wrong (be specific — reference the line)
2. **Why it matters**: Which rule/skill is violated and what the impact is
3. **Fix**: Concrete corrected code (show don't tell)
4. **Severity**: `🔴 Critical` | `🟡 Warning` | `🔵 Suggestion`

### Severity Guide

| Severity | Examples |
|---|---|
| 🔴 **Critical** | SOQL in Service, DML without UoW, logic in trigger file, hardcoded namespace, `without sharing` without `@FalsePositive`, PMD violation (ExcessiveParameterList / CyclomaticComplexity), LWC underscore prefix, inline selector stub in test |
| 🟡 **Warning** | Missing ApexDoc, missing `data-id` on interactive element, DML test missing for global method, schema test missing for new field, selector not using `newQueryFactory` |
| 🔵 **Suggestion** | Style improvements, optional optimizations, alternative patterns that may be cleaner |

---

## Approval Criteria

✅ No architectural violations (wrong layer, logic in trigger, SOQL in service)
✅ No security violations (`without sharing` undocumented, missing FLS)
✅ No PMD critical violations (ExcessiveParameterList, CyclomaticComplexity)
✅ ApexDoc present on all public/global methods
✅ Test coverage meets requirements (85%+ mock, DML for globals, schema for new fields)
✅ No hardcoded namespace or org-specific IDs
✅ LWC: `data-id` present, no underscore prefix, proper SLDS usage

---

## Skill File Quick Reference

| Skill | File Path |
|---|---|
| Overall architecture & quality gates | `skills/salesforce-architecture/SKILL.md` |
| Selector (data access) pattern | `skills/apex-selector-pattern/SKILL.md` |
| Service (business logic) pattern | `skills/apex-service-pattern/SKILL.md` |
| Trigger framework (MetadataTriggerHandler) | `skills/apex-trigger-framework/SKILL.md` |
| Data Processor (batch/async) pattern | `skills/apex-data-processor/SKILL.md` |
| Apex coding standards & PMD rules | `skills/apex-development/SKILL.md` |
| Test strategy (three-tier: mock/DML/schema) | `skills/apex-testing/SKILL.md` |
| MockApexClasses selector mocking | `skills/apex-testing-mocking/SKILL.md` |
| LWC component development | `skills/lwc-development/SKILL.md` |
| LWC Jest testing patterns | `skills/lwc-jest-testing/SKILL.md` |
| LWC–Apex controller integration | `skills/lwc-controller-integration/SKILL.md` |
| 2GP packaging & backward compatibility | `skills/packaging-isvforce/SKILL.md` |
| Custom Metadata Types configuration | `skills/metadata-configuration/SKILL.md` |
| Nebula Logger usage | `skills/logger-framework/SKILL.md` |
| Experience Cloud / guest user patterns | `skills/experience-cloud-configuration/SKILL.md` |
