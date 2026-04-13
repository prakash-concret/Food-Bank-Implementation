---
name: apex-selector-pattern
description: Implementation guide for fflib Selector pattern in Element AMS. Use when creating or modifying data query classes that inherit from fflib_SObjectSelector. Covers singleton pattern, query factory usage, security models, and integration with services and domains.
---

# Apex Selector Pattern

## Purpose

The Selector pattern provides a **centralized, reusable data query layer** for SObjects using the fflib (FinancialForce Library) framework. Selectors enforce separation of concerns by isolating all SOQL queries from business logic.

## When to Use This Skill

- Creating a new Selector class for querying SObject data
- Adding query methods to existing Selectors
- Implementing dynamic queries with filtering
- Ensuring proper security and sharing rules
- Integrating Selectors with Service or Domain classes

## Core Principles

### 1. Single Responsibility
Each Selector handles queries for **one SObject type only**.

### 2. Inheritance
All Selectors extend `fflib_SObjectSelector` from `apex-common`.

### 3. Singleton Pattern
Use `getInstance()` for dependency injection and testing flexibility.

### 4. Security First
Default to `inherited sharing` unless system mode is explicitly required with `@FalsePositive` documentation.

### 5. Query Factory
Use `newQueryFactory()` for all dynamic queries to leverage fflib capabilities.

## Implementation Pattern

### Basic Selector Structure

```apex
/**
 * @description Selector class for Account object
 * @group Selectors
 */
public inherited sharing class AccountSelector extends fflib_SObjectSelector {
    @TestVisible
    private static AccountSelector instance;

    // Singleton pattern
    public static AccountSelector getInstance() {
        if (instance == null) {
            instance = new AccountSelector();
        }
        return instance;
    }

    // For test dependency injection
    @TestVisible
    private static void setInstance(AccountSelector mockInstance) {
        instance = mockInstance;
    }

    // Required: Return SObject type
    public Schema.SObjectType getSObjectType() {
        return Account.SObjectType;
    }

    // Required: Define default fields
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Account.Id,
            Account.Name,
            Account.BillingCity,
            Account.BillingState
        };
    }

    // Standard query by Ids
    public List<Account> selectById(Set<Id> idSet) {
        return (List<Account>) selectSObjectsById(idSet);
    }

    // Dynamic query example
    public List<Account> selectByName(Set<String> names) {
        return Database.query(
            newQueryFactory()
                .setCondition('Name IN :names')
                .toSOQL()
        );
    }

    // Query with custom fields
    public List<Account> selectByIdWithCustomFields(
        Set<Id> idSet, 
        List<String> additionalFields
    ) {
        return Database.query(
            newQueryFactory()
                .selectFields(additionalFields)
                .setCondition('Id IN :idSet')
                .toSOQL()
        );
    }
}
```

## Key Elements

### Required Methods

1. **getSObjectType()** - Returns the SObject schema type
2. **getSObjectFieldList()** - Defines default fields queried by `selectSObjectsById()`

### Recommended Methods

- `selectById(Set<Id>)` - Standard ID-based query
- Custom query methods following naming: `selectBy<Criteria>()`

### Query Factory Usage

```apex
// Basic query
newQueryFactory().toSOQL()

// With condition
newQueryFactory()
    .setCondition('Status__c = :status')
    .toSOQL()

// With additional fields
newQueryFactory()
    .selectFields(customFieldList)
    .setCondition('CreatedDate = TODAY')
    .toSOQL()

// With related fields
newQueryFactory()
    .selectField('Account.Name')
    .selectField('Owner.Email')
    .toSOQL()

// With ordering
newQueryFactory()
    .setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING)
    .toSOQL()
```

## Security Models

### Inherited Sharing (Default)

```apex
public inherited sharing class AccountSelector extends fflib_SObjectSelector {
    // Respects calling context's sharing rules
}
```

### System Mode (Use Sparingly)

```apex
/**
 * @FalsePositive - System mode required for administrative reports
 * that need to aggregate data across all accounts regardless of sharing.
 * Approved by Security team on 2024-01-15.
 */
public without sharing class AccountSelector extends fflib_SObjectSelector {
    // Runs in system mode
}
```

> **IMPORTANT**: Always document WHY system mode is needed with `@FalsePositive` annotation.

## Testing Strategy

See `apex-testing-mocking` skill for detailed testing patterns.

### Mock Test (in force-app)

```apex
@IsTest
private class AccountSelectorTest {
    @IsTest
    static void testSelectById() {
        // Create mock
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        AccountSelector mockSelector = 
            (AccountSelector) mocks.mock(AccountSelector.class);
        
        // Set expectations
        Set<Id> testIds = new Set<Id>{
            fflib_IDGenerator.generate(Account.SObjectType)
        };
        List<Account> expectedAccounts = new List<Account>{
            new Account(Id = testIds.iterator().next(), Name = 'Test')
        };
        
        mocks.startStubbing();
        mocks.when(mockSelector.selectById(testIds))
            .thenReturn(expectedAccounts);
        mocks.stopStubbing();
        
        // Inject mock
        AccountSelector.setInstance(mockSelector);
        
        // Test
        Test.startTest();
        List<Account> result = AccountSelector.getInstance()
            .selectById(testIds);
        Test.stopTest();
        
        // Verify
        System.assertEquals(1, result.size());
        System.assertEquals('Test', result[0].Name);
    }
}
```

## Interactions with Other Skills

### Called By
- **apex-service-pattern** - Services use Selectors for data retrieval
- **apex-data-processor** - Data processors query records via Selectors

### Uses
- **apex-common** - Extends fflib_SObjectSelector
- **apex-testing-mocking** - Uses ApexMocks for testing

### Related
- **metadata-configuration** - May query custom metadata via Selectors
- **logger-framework** - Can log query performance metrics

## Do's and Don'ts

### ✅ DO

- Use `Schema.SObjectField` references, never hardcoded strings
- Implement singleton pattern with `getInstance()`
- Provide `setInstance()` for test mocking
- Use `newQueryFactory()` for all dynamic queries
- Default to `inherited sharing`
- Group related query methods in the same Selector
- Document complex query logic
- Use bind variables for security

### ❌ DON'T

- Write SOQL directly in Service or Domain classes
- Use `without sharing` without `@FalsePositive` documentation
- Hardcode field names as strings
- Create multiple Selectors for the same SObject
- Mix DML operations in Selector classes
- Use dynamic SOQL without proper sanitization
- Forget to include Id in `getSObjectFieldList()`

## Common Patterns

### Namespace-Aware Queries

```apex
public List<Product__c> selectActiveProducts() {
    String query = newQueryFactory()
        .setCondition('Active__c = true')
        .toSOQL();
    return Database.query(query);
}
```

### Parent-Child Relationships

```apex
public List<Account> selectWithContacts(Set<Id> accountIds) {
    fflib_QueryFactory qf = newQueryFactory();
    
    // Add child relationship
    fflib_QueryFactory contactQF = 
        new fflib_QueryFactory(Contact.SObjectType);
    contactQF.selectField('FirstName')
             .selectField('LastName')
             .selectField('Email');
    
    qf.subselectQuery('Contacts')
      .selectFields(contactQF.getSelectedFields());
    
    qf.setCondition('Id IN :accountIds');
    
    return Database.query(qf.toSOQL());
}
```

### Aggregate Queries

```apex
public Map<Id, Decimal> getTotalRevenueByAccount(Set<Id> accountIds) {
    Map<Id, Decimal> revenueMap = new Map<Id, Decimal>();
    
    String query = 'SELECT Account__c, SUM(Amount__c) total ' +
                   'FROM Invoice__c ' +
                   'WHERE Account__c IN :accountIds ' +
                   'GROUP BY Account__c';
    
    for (AggregateResult ar : Database.query(query)) {
        revenueMap.put(
            (Id) ar.get('Account__c'),
            (Decimal) ar.get('total')
        );
    }
    
    return revenueMap;
}
```

## Anti-Patterns

### ❌ Direct SOQL in Service Layer

```apex
// WRONG - Don't do this in Service classes
public class MembershipService {
    public List<Membership__c> getActiveMemberships() {
        return [SELECT Id, Name FROM Membership__c WHERE Active__c = true];
    }
}

// CORRECT - Use Selector
public class MembershipService {
    public List<Membership__c> getActiveMemberships() {
        return MembershipSelector.getInstance().selectActive();
    }
}
```

### ❌ Hardcoded Field Names

```apex
// WRONG
return Database.query(
    newQueryFactory()
        .selectField('element__Account__c')  // Hardcoded namespace
        .toSOQL()
);

// CORRECT
return Database.query(
    newQueryFactory()
        .selectField(Invoice__c.Account__c)  // Schema reference
        .toSOQL()
);
```

## Element-Specific Conventions

1. **Location**: All Selectors in `force-app/selector/main/classes/`
2. **Naming**: `<SObjectName>Selector.cls`
3. **Test Location**: `force-app/selector/test/classes/<SObjectName>SelectorTest.cls`
4. **Namespace Handling**: Use Schema references to handle `element__` namespace automatically

## Related Documentation

- [fflib Selector Pattern](references/fflib-selector-api.md) - Complete API reference
- [Query Optimization](references/query-performance.md) - Performance best practices
- [Security Guidelines](references/security-patterns.md) - Sharing and FLS patterns
