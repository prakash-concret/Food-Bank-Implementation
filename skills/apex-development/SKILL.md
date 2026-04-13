---
name: apex-development
description: Apex coding standards and patterns for Element AMS. Use when writing Apex code, implementing business logic, handling errors, managing governor limits, or applying security practices. Covers naming conventions, bulkification (200+ records), error handling, CRUD/FLS, ApexDoc standards. For async operations, references apex-data-processor pattern.
---

# Apex Development

## Purpose

Defines **Apex coding standards** for Element AMS, ensuring consistent, performant, secure code across the package.

## When to Use

- Analyze the existing code to determine best possible solution
- Take decisions whether to update existing code or create new one service/class
- Writing any Apex class or method following the fflib patterns & opps concepts
- [Follow the salesforce best practices](https://developer.salesforce.com/ja/wiki/apex_code_best_practices)
- Reviewing code quality
- Questions about Apex syntax or limitations
- Implementing business logic
- Handling errors or exceptions

## Naming Conventions

### Classes

| Type | Pattern | Example |
|------|---------|---------|
| Selector | `<SObject>Selector` | `AccountSelector` |
| Service | `<Function>Service` | `MembershipService` |
| Trigger Action | `TA_<SObject>_<Operation>` | `TA_Account_ValidateDates` |
| Data Processor | `<Purpose>DataProcessor` | `AutoRenewMembershipDataProcessor` |
| Controller | `<Component>Controller` | `ShoppingCartController` |
| Test | `<ClassName>Test` | `AccountSelectorTest` |
| Utility | `<Purpose>Util` | `CommunityUtil` |

### Methods

```apex

// Private methods: camelCase
private Decimal calculateAmount(Membership__c membership) { }

// Test methods: camelCase with descriptive names
@IsTest
static void testRenewMembership_WithValidData_CreatesInvoice() { }
```

### Variables

```apex
// Local variables: camelCase
String accountName = 'Test';

// Constants: UPPER_SNAKE_CASE
private static final String DEFAULT_STATUS = 'Active';

// Collections: plural nouns
List<Account> accounts = new List<Account>();
Map<Id, Account> accountMap = new Map<Id, Account>();
Set<Id> accountIds = new Set<Id>();
```

**Never use Apex reserved keywords as variable names.** Common offenders that look like valid identifiers but are reserved:

| Keyword | Safe alternative |
|---------|-----------------|
| `group` | `requirementGroup`, `recordGroup`, `sObjectGroup` |
| `object` | `sObjectRecord`, `targetObject` |
| `list` | `recordList`, `itemList` |
| `map` | `fieldMap`, `recordMap` |
| `set` | `idSet`, `recordSet` |
| `type` | `sObjectType`, `recordType` |
| `limit` | `queryLimit`, `rowLimit` |

```apex
// BAD — 'group' is a reserved keyword (used in SOQL GROUP BY)
Credential_Requirement_Group__c group = credentialRequirements[0].Credential_Requirement_Group__r;

// GOOD
Credential_Requirement_Group__c requirementGroup = credentialRequirements[0].Credential_Requirement_Group__r;
```

## Code Templates

### Service Class

```apex
/**
 * @description Service for [business function]
 * @group Services
 */
public inherited sharing class [Function]Service {
    @TestVisible
    private static [Function]Service instance;

    public static [Function]Service getInstance() {
        if (instance == null) {
            instance = new [Function]Service();
        }
        return instance;
    }

    @TestVisible
    private static void setInstance([Function]Service mockInstance) {
        instance = mockInstance;
    }

    /**
     * @description [Method purpose]
     * @param [paramName] [Description]
     * @return [Return description]
     */
    public [ReturnType] [methodName]([ParamType] [paramName]) {
        // Implementation
    }
}
```

### Controller Class

```apex
/**
 * @description Controller for [Component Name]
 * @group Controllers
 */
public with sharing class [Component]Controller {
    
    /**
     * @description [Method purpose]
     * @param [paramName] [Description]
     * @return [Return description]
     */
    @AuraEnabled(cacheable=true)
    public static [ReturnType] [methodName]([ParamType] [paramName]) {
        try {
            // Delegate to Service
            return [Function]Service.getInstance().[method]([params]);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
```

## Bulkification Requirements

> [!IMPORTANT]
> **Minimum test standard**: 200 records per operation

### Query Bulkification

```apex
// CORRECT - Query once
Set<Id> accountIds = new Set<Id>();
for (Contact c : contacts) {
    accountIds.add(c.AccountId);
}
Map<Id, Account> accountMap = new Map<Id, Account>(
    AccountSelector.getInstance().selectById(accountIds)
);

for (Contact c : contacts) {
    Account acc = accountMap.get(c.AccountId);
    // Use acc
}

// WRONG - Query in loop  
for (Contact c : contacts) {
    Account acc = [SELECT Id FROM Account WHERE Id = :c.AccountId];
}
```

### DML Bulkification

```apex
// CORRECT - Use UnitOfWork
fflib_ISObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
    new List<Schema.SObjectType>{
        Account.SObjectType,
        Contact.SObjectType
    }
);

for (Account acc : accounts) {
    uow.registerDirty(acc);
}

uow.commitWork();

// WRONG - DML in loop
for (Account acc : accounts) {
    update acc;
}
```

## Error Handling

### Service Layer

```apex
public class ProcessException extends Exception {}

public void processRecords(List<Record__c> records) {
    try {
        // Validation
        if (records == null || records.isEmpty()) {
            throw new ProcessException('No records provided');
        }
        
        // Processing
        // ...
        
    } catch (DmlException e) {
        // Log DML errors
        Logger.error('DML Error processing records', e);
        Logger.saveLog();
        throw new ProcessException('Failed to process records: ' + e.getMessage());
    } catch (Exception e) {
        // Log unexpected errors
        Logger.error('Unexpected error', e);
        Logger.saveLog();
        throw;
    }
}
```

### Controller Layer

```apex
@AuraEnabled
public static void updateAccount(Account account) {
    try {
        AccountService.getInstance().updateAccount(account);
    } catch (ServiceException e) {
        // User-friendly message
        throw new AuraHandledException(e.getMessage());
    } catch (Exception e) {
        // Log and throw generic message
        Logger.error('Error updating account', e);
        Logger.saveLog();
        throw new AuraHandledException('An error occurred. Please contact support.');
    }
}
```

## Security Practices

### Sharing Rules

```apex
// Default: inherited sharing
public inherited sharing class AccountService { }

// System mode: requires @FalsePositive documentation
/**
 * @FalsePositive - System mode required for [reason]
 * [Detailed justification]
 * Approved: [Date, Ticket]
 */
public without sharing class AdminService { }
```

### CRUD/FLS Enforcement

```apex
// Check field accessibility
if (!Schema.SObjectType.Account.fields.AnnualRevenue.isAccessible()) {
    throw new SecurityException('No access to Annual Revenue field');
}

// Use fflib for comprehensive checks
fflib_SecurityUtils.checkFieldIsReadable(
    Account.SObjectType,
    'AnnualRevenue'
);

fflib_SecurityUtils.checkObjectIsInsertable(Account.SObjectType);
```

## Governor Limits Management

### SOQL Limits

```apex
// CORRECT - Single query with filters
List<Account> accounts = AccountSelector.getInstance()
    .selectByTypeAndStatus('Customer', 'Active');

// Track usage in complex methods
System.debug('SOQL used: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
```

### DML Limits

```apex
// CORRECT - Bulk DML via UnitOfWork
fflib_ISObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(...);
// Register all operations
uow.commitWork(); // Single DML operation

// Monitor
System.debug('DML used: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements());
```

### CPU Time

```apex
// For heavy processing, use async
if (Limits.getCpuTime() > 8000) { // Approaching limit
    // Consider moving to @future or Queueable
    Logger.warn('CPU time approaching limit');
}
```

### Heap Size

```apex
// Monitor heap usage
Long heapUsed = Limits.getHeapSize();
Long heapLimit = Limits.getLimitHeapSize();

if (heapUsed > heapLimit * 0.8) {
    Logger.warn('Heap size at 80%');
}
```

## Asynchronous Apex Patterns

> [!NOTE]
> **For Element async operations**: Use `apex-data-processor` skill pattern

Element's async processing follows the **DataProcessor pattern** for consistency. Examples below show standard Salesforce async, but prefer DataProcessor for Element.

### When to Use Async

- Processing \u003e 200 records
- Long-running operations
- Callouts to external systems
- Operations approaching governor limits
- Scheduled batch jobs

### Quick Reference

| Pattern | Use Case | See |
|---------|----------|-----|
| **DataProcessor** | Element scheduled operations, Large data volumes (\u003e 10k records) | `apex-data-processor` skill |
| **@future** | Simple async operations, callouts | Standard Apex |
| **Queueable** | Chained jobs, complex async logic | Standard Apex |

### Future Methods

```apex
@future
public static void sendEmailAsync(List<Id> contactIds) {
    // Future method logic
    // Cannot accept SObjects as parameters
}
```

### Queueable

```apex
public class ProcessRecordsQueueable implements Queueable {
    private List<Record__c> records;
    
    public ProcessRecordsQueueable(List<Record__c> records) {
        this.records = records;
    }
    
    public void execute(QueueableContext context) {
        // Process records
        // Can chain another queueable if needed
        if (hasMoreWork) {
            System.enqueueJob(new AnotherQueueable());
        }
    }
}

// Enqueue
System.enqueueJob(new ProcessRecordsQueueable(records));
```

## ApexDoc Standards

### Class Documentation

```apex
/**
 * @description Service class for membership renewal operations
 * @group Services
 * @see MembershipSelector
 * @since 1.5.0
 */
public class MembershipService {
```

### Method Documentation

```apex
/**
 * @description Renews memberships and creates invoices
 * @param membershipIds Set of membership IDs to renew
 * @return Map of membership ID to new invoice ID
 * @throws ServiceException if renewal fails
 * @example
 * Set<Id> ids = new Set<Id>{membership.Id};
 * Map<Id, Id> result = MembershipService.getInstance().renewMemberships(ids);
 */
public Map<Id, Id> renewMemberships(Set<Id> membershipIds) {
```

### Inline Comments

```apex
// Good: Explains WHY
// We use system mode here because admin reports need cross-org visibility

// Less useful: Explains WHAT (code already shows this)
// Loop through accounts
for (Account acc : accounts) {
```

## Common Patterns

### Null Safety

```apex
// Safe navigation
Decimal amount = invoice?.Total_Amount__c ?? 0;

// Null checks
if (String.isBlank(accountName)) {
    throw new ProcessException('Account name required');
}

if (accounts == null || accounts.isEmpty()) {
    return new List<Invoice__c>();
}
```

### Collection Operations

```apex
// Extract IDs
Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

// Group by field
Map<Id, List<Contact>> contactsByAccount = new Map<Id, List<Contact>>();
for (Contact c : contacts) {
    if (!contactsByAccount.containsKey(c.AccountId)) {
        contactsByAccount.put(c.AccountId, new List<Contact>());
    }
    contactsByAccount.get(c.AccountId).add(c);
}

// Filter collection
List<Account> activeAccounts = new List<Account>();
for (Account acc : accounts) {
    if (acc.Active__c) {
        activeAccounts.add(acc);
    }
}
```

## PMD Code Quality Rules

PMD static analysis runs on every PR. Two rules require active design attention — violations block merge.

### Rule 1: ExcessiveParameterList — max 3 parameters per method

A method with more than 3 parameters is a PMD violation. Refactor by grouping related parameters into a wrapper/DTO inner class.

```apex
// ❌ VIOLATES PMD — 4 parameters
public void createInvoice(Id accountId, Date invoiceDate, String status, Decimal amount) { }

// ✅ COMPLIANT — group into a request object
public class InvoiceRequest {
    public Id accountId;
    public Date invoiceDate;
    public String status;
    public Decimal amount;

    public InvoiceRequest(Id accountId, Date invoiceDate, String status, Decimal amount) {
        this.accountId  = accountId;
        this.invoiceDate = invoiceDate;
        this.status      = status;
        this.amount      = amount;
    }
}

public void createInvoice(InvoiceRequest request) { }
```

**When to apply:** Any method — public, private, or `@AuraEnabled` — with more than 3 parameters. Constructors count too.

**Pattern for `@AuraEnabled` controllers:** Apex REST / AuraEnabled methods often accumulate parameters. Wrap them:

```apex
// ❌ VIOLATES PMD
@AuraEnabled
public static String processPayment(Id membershipId, String method, Decimal amount, Boolean sendReceipt) { }

// ✅ COMPLIANT — single wrapper parameter
public class PaymentRequest {
    @AuraEnabled public Id membershipId;
    @AuraEnabled public String method;
    @AuraEnabled public Decimal amount;
    @AuraEnabled public Boolean sendReceipt;
}

@AuraEnabled
public static String processPayment(PaymentRequest request) { }
```

---

### Rule 2: CyclomaticComplexity — max 10 per method (PMD default)

Cyclomatic complexity counts the number of independent execution paths through a method. Each `if`, `else if`, `for`, `while`, `do`, `catch`, `case`, `&&`, `||`, and ternary (`?:`) adds 1 to the count (starting from 1).

**PMD threshold: 10.** A method with complexity > 10 is a violation.

**How to reduce complexity — extract private helper methods:**

```apex
// ❌ VIOLATES PMD — complexity ≈ 12
public void processMembership(Membership__c m) {
    if (m == null) { return; }                          // +1
    if (m.Status__c == 'Active') {                      // +1
        if (m.Auto_Renew__c) {                          // +1
            if (m.End_Date__c <= Date.today()) {        // +1
                if (m.Payment_Method__c != null) {      // +1
                    renewMembership(m);
                } else {
                    notifyMissingPayment(m);
                }
            }
        } else if (m.Status__c == 'Expired') {          // +1
            if (m.Grace_Period__c > 0) {                // +1
                applyGracePeriod(m);
            } else {
                archiveMembership(m);
            }
        }
    }
    for (Contact c : m.Contacts__r) {                   // +1
        if (c.Email != null) {                          // +1
            sendNotification(c);
        }
    }
}

// ✅ COMPLIANT — complexity distributed across focused helpers
public void processMembership(Membership__c m) {
    if (m == null) { return; }
    handleStatusLogic(m);
    notifyContacts(m.Contacts__r);
}

private void handleStatusLogic(Membership__c m) {
    if (m.Status__c == 'Active') {
        handleActiveMembership(m);
    } else if (m.Status__c == 'Expired') {
        handleExpiredMembership(m);
    }
}

private void handleActiveMembership(Membership__c m) {
    if (!m.Auto_Renew__c || m.End_Date__c > Date.today()) { return; }
    if (m.Payment_Method__c != null) {
        renewMembership(m);
    } else {
        notifyMissingPayment(m);
    }
}

private void handleExpiredMembership(Membership__c m) {
    if (m.Grace_Period__c > 0) {
        applyGracePeriod(m);
    } else {
        archiveMembership(m);
    }
}

private void notifyContacts(List<Contact> contacts) {
    for (Contact c : contacts) {
        if (c.Email != null) { sendNotification(c); }
    }
}
```

**Complexity contributors to watch for:**

| Construct | Adds to complexity |
|---|---|
| `if` / `else if` | +1 each branch |
| `for` / `while` / `do-while` | +1 |
| `catch` block | +1 |
| `case` in `switch` | +1 per case |
| `&&` / `\|\|` in conditions | +1 per operator |
| Ternary `? :` | +1 |

**Design rule:** If a method needs more than ~3 conditional branches or 1 loop with inner conditions, extract a helper. Each private helper should have a single, named responsibility.

---

### Checking Before Committing

Before raising a PR mentally verify each new or modified method:
1. **Parameter count ≤ 3** — if more, create a request/DTO inner class
2. **No deeply nested if-in-if-in-loop blocks** — if present, extract named private helpers until each method reads like a sentence

## Do's and Don'ts

### ✅ DO

- Use singleton pattern for Services and Selectors
- Bulkify all operations (test with 200+ records)
- Validate inputs
- Handle exceptions appropriately
- Log errors using Logger framework
- Write ApexDoc for public methods
- Use `inherited sharing` by default
- Reference `apex-data-processor` for async Element operations

### ❌ DON'T

- Write SOQL in Services (use Selectors)
- Perform DML without UnitOfWork
- Use static methods without singleton pattern
- Hardcode IDs or namespace
- Suppress exceptions without logging
- Use `without sharing` without `@FalsePositive`
- Query or perform DML in loops
- Ignore governor limits
- Write methods with more than 3 parameters (PMD: ExcessiveParameterList)
- Write methods with cyclomatic complexity > 10 (PMD: CyclomaticComplexity) — extract private helpers

## Interactions with Other Skills

### Uses
- **apex-data-processor** - For Element async patterns
- **apex-selector-pattern** - For data access
- **apex-service-pattern** - For business logic
- **logger-framework** - For logging

### Called By
- All Apex development tasks
- **apex-trigger-framework** - Action classes follow these standards
- **lwc-development** - Controllers follow these standards

### References
- **salesforce-architecture** - For architectural guidance
- **packaging-isvforce** - For namespace considerations

## Quick Reference

| Task | Guideline |
|------|-----------|
| Naming class | Follow type-specific pattern (see table) |
| Writing method | PascalCase public, camelCase private |
| Bulkification | Test with 200+ records minimum |
| Error handling | Try/catch, log errors, throw meaningful exceptions |
| Security | `inherited sharing` default, document system mode |
| Async processing | Use `apex-data-processor` pattern for Element |
| Documentation | ApexDoc on all public methods |
| Testing | 85%+ coverage, mock with ApexMocks |
| PMD: parameter count | Max 3 — wrap extras in an inner request/DTO class |
| PMD: cyclomatic complexity | Max 10 per method — extract named private helpers |
