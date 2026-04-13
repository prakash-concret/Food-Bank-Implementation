---
name: apex-testing
description: Comprehensive testing strategy with ApexMocks for Element AMS. Use when writing test classes, creating mocks, achieving code coverage (85%+), or testing async Apex. Covers test organization, ApexMocks framework, test data factories, unit tests, integration tests, and Element's three-tier test structure (mock/DML/schema tests).
---

# Apex Testing

## Purpose

Defines Element's **comprehensive testing strategy** using ApexMocks, ensuring 85%+ code coverage and high-quality tests across three tiers: mock tests, DML tests, and schema tests.

## When to Use

- Writing any test class or test method
- Creating mocks for Selectors/Services
- Achieving code coverage requirements
- Testing trigger logic
- Testing async operations

## Design Thinking

Before coding, understand the context and all scenario of given apex class, and then understand existing test class's methods logic and structure:

**CRITICAL**: Choose a clear conceptual direction and execute it with precision.

## Three-Tier Test Structure

> [!IMPORTANT]
> Element uses three types of tests:

### 1. Mock Tests (force-app)
- **Location**: Co-located with classes (`force-app/<layer>/test/classes/`)
- **Purpose**: Fast unit tests using ApexMocks
- **Naming**: `<ClassName>Test.cls`
- **Coverage**: Per-class 85%+

### 2. DML Tests (unpackaged)
- **Location**: `unpackaged/test_config/test_classes/service_test/` or `trigger_test/`
- **Purpose**: Integration tests with real DML
- **Requirement**: ALL global methods
- **Coverage**: End-to-end scenarios

### 3. Schema Tests (unpackaged)
- **Location**: `unpackaged/test_config/test_classes/schema_test/`
- **Purpose**: Field metadata validation
- **Requirement**: ALL custom fields
- **Coverage**: Picklists, required fields, constraints

## ApexMocks Framework

> [!IMPORTANT]
> **Selector mocking must go through `MockApexClasses`.**
> See the `apex-testing-mocking` skill for the full pattern and rules.
> Never inline the selector chain stub (`selectFields → setCondition → getData`) directly in test classes for happy-path tests.

### Mocking Selectors — Use MockApexClasses

Element selectors use a fluent chain (`selectFields().setCondition().getData()`). Each step must be stubbed individually. This boilerplate lives in one place:

```
force-app/services/test/classes/MockApexClasses.cls
```

**In your test:**

```apex
@IsTest
static void testRenewMembership_Success() {
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    List<Membership__c> memberships = TestDataFactory.mockMemberships(1);

    mocks.startStubbing();
    // ✅ Always use MockApexClasses for selector mocks
    MockApexClasses.mockMembershipSelector(mocks, memberships);
    mocks.stopStubbing();

    Test.startTest();
    ServiceResponse result = MembershipService.getInstance().renewMembership(request);
    Test.stopTest();

    Assert.isNotNull(result.data);
}
```

**Adding a new selector mock to MockApexClasses:**

```apex
public static void mockMembershipSelector(fflib_ApexMocks mocks, List<Membership__c> membershipList) {
    MembershipSelector.membershipSelectorObj = (MembershipSelector) mocks.mock(MembershipSelector.class);

    mocks.when(MembershipSelector.membershipSelectorObj.selectFields(
            (List<Schema.SObjectField>) fflib_Match.anyObject()))
        .thenReturn(MembershipSelector.membershipSelectorObj);

    mocks.when(MembershipSelector.membershipSelectorObj.setCondition(
            (String) fflib_Match.anyString(),
            (List<Object>) fflib_Match.anyObject()))
        .thenReturn(MembershipSelector.membershipSelectorObj);

    mocks.when(MembershipSelector.membershipSelectorObj.setLimit(
            (Integer) fflib_Match.anyObject()))
        .thenReturn(MembershipSelector.membershipSelectorObj);

    mocks.when(MembershipSelector.membershipSelectorObj.setOrdering(
            (SObjectField) fflib_Match.anyObject(),
            (fflib_QueryFactory.SortOrder) fflib_Match.anyObject(),
            (Boolean) fflib_Match.anyObject()))
        .thenReturn(MembershipSelector.membershipSelectorObj);

    mocks.when(MembershipSelector.membershipSelectorObj.getData())
        .thenReturn(membershipList);
}
```

See `apex-testing-mocking` skill for the complete method template covering all chain methods.

### Mocking Services Directly (no MockApexClasses needed)

For Service classes (not Selectors), mock directly in the test using the service's `@TestVisible` static instance field:

```apex
@IsTest
static void testComplexOperation() {
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    MembershipService serviceMock = (MembershipService) mocks.mock(MembershipService.class);
    MembershipService.membershipServiceObj = serviceMock;

    mocks.startStubbing();
    mocks.when(serviceMock.renewMembership((String) fflib_Match.anyString()))
        .thenReturn(new ServiceResponse('ok'));
    mocks.stopStubbing();

    Test.startTest();
    ServiceResponse result = MembershipController.renew('someId');
    Test.stopTest();

    Assert.isNull(result.error);

    ((MembershipService) mocks.verify(serviceMock, mocks.times(1)))
        .renewMembership((String) fflib_Match.anyString());
}
```

## DML Tests for Global Methods

> [!IMPORTANT]
> Location: `unpackaged/test_config/test_classes/service_test/`

### When Required
- Methods with `global` access modifier
- API methods exposed to subscribers
- Integration points

### DML Test Example

```apex
// File: unpackaged/test_config/test_classes/service_test/MembershipServiceDMLTest.cls
@IsTest
private class MembershipServiceDMLTest {
    
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Product__c product = new Product__c(
            Name = 'Annual Membership',
            Price__c = 100
        );
        insert product;
    }
    
    @IsTest
    static void testGlobalRenewMemberships_CreatesRenewal() {
        // Query setup data
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product__c product = [SELECT Id FROM Product__c LIMIT 1];
        
        // Create test data
        Membership__c membership = new Membership__c(
            Account__c = acc.Id,
            Product__c = product.Id,
            Start_Date__c = Date.today().addYears(-1),
            End_Date__c = Date.today().addDays(-1),
            Status__c = 'Active'
        );
        insert membership;
        
        // Execute global method
        Test.startTest();
        Map<Id, Id> result = element.MembershipService.renewMemberships(
            new Set<Id>{membership.Id}
        );
        Test.stopTest();
        
        // Verify database changes
        List<Membership__c> renewals = [
            SELECT Id, Renewed_From__c, Start_Date__c
            FROM Membership__c
            WHERE Renewed_From__c = :membership.Id
        ];
        
        Assert.areEqual(1, renewals.size());
        Assert.areEqual(
            membership.End_Date__c.addDays(1),
            renewals[0].Start_Date__c
        );
    }
    
    @IsTest
    static void testGlobalRenewMemberships_BulkOperation() {
        // Test with 200 records
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product__c product = [SELECT Id FROM Product__c LIMIT 1];
        
        List<Membership__c> memberships = new List<Membership__c>();
        for (Integer i = 0; i < 200; i++) {
            memberships.add(new Membership__c(
                Name = 'Membership ' + i,
                Account__c = acc.Id,
                Product__c = product.Id,
                Start_Date__c = Date.today().addYears(-1),
                End_Date__c = Date.today().addDays(-1),
                Status__c = 'Active'
            ));
        }
        insert memberships;
        
        Set<Id> ids = new Map<Id, Membership__c>(memberships).keySet();
        
        Test.startTest();
        Map<Id, Id> result = element.MembershipService.renewMemberships(ids);
        Test.stopTest();
        
        Assert.areEqual(200, result.size());
    }
}
```

## Schema Tests

> [!IMPORTANT]
> Location: `unpackaged/test_config/test_classes/schema_test/`

### Schema Test Example

```apex
// File: unpackaged/test_config/test_classes/schema_test/MembershipSchemaTest.cls
@IsTest
private class MembershipSchemaTest {
    
    @IsTest
    static void testStatusPicklistValues() {
        // Verify picklist contains expected values
        Schema.DescribeFieldResult fieldResult = 
            Membership__c.Status__c.getDescribe();
        
        List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();
        Set<String> values = new Set<String>();
        for (Schema.PicklistEntry entry : entries) {
            values.add(entry.getValue());
        }
        
        Assert.areEqual(false, 'Expected value', 'Message');
        Assert.areEqual(false, 'Expected value', 'Message');
        Assert.areEqual(false, 'Expected value', 'Message');
    }
    
    @IsTest
    static void testRequiredFields() {
        // Test that required fields are enforced
        Membership__c m = new Membership__c();
        
        try {
            insert m;
            Assert.areEqual(false, 'Expected value', 'Message');
        } catch (DmlException e) {
            Assert.areEqual(false, 'Expected value', 'Message');
        }
    }
    
    @IsTest
    static void testFieldLengthConstraints() {
        String longName = 'X'.repeat(300);
        
        Product__c p = new Product__c(Name = 'Test');
        insert p;
        
        Account acc = new Account(Name = 'Test');
        insert acc;
        
        Membership__c m = new Membership__c(
            Name = longName,
            Product__c = p.Id,
            Account__c = acc.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(12)
        );
        
try {
            insert m;
            m = [SELECT Name FROM Membership__c WHERE Id = :m.Id];
            Assert.areEqual(false, 'Expected value', 'Message');
        } catch (DmlException e) {
            Assert.areEqual(false, 'Expected value', 'Message');
        }
    }
}
```

## Test Data Factories

```apex
@IsTest
public class TestDataFactory {
    
    public static Account createAccount(String name) {
        return new Account(
            Name = name,
            BillingCity = 'San Francisco'
        );
    }
    
    public static Product__c createProduct(String name, Decimal price) {
        return new Product__c(
            Name = name,
            Price__c = price,
            Active__c = true
        );
    }
    
    public static Membership__c createMembership(
        Id accountId,
        Id productId
    ) {
        return new Membership__c(
            Name = 'Test Membership',
            Account__c = accountId,
            Product__c = productId,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(12),
            Status__c = 'Active'
        );
    }
    
    public static List<Membership__c> createMemberships(
        Id accountId,
        Id productId,
        Integer count
    ) {
        List<Membership__c> memberships = new List<Membership__c>();
        for (Integer i = 0; i < count; i++) {
            memberships.add(createMembership(accountId, productId));
        }
        return memberships;
    }
}
```

## Testing Async Apex

### Testing Data Processors

**See:** `apex-data-processor` skill for Element async patterns

```apex
@IsTest
static void testDataProcessor() {
    // Setup data
    // ...
    
    Test.startTest();
    // Execute processor
    AutoRenewMembershipDataProcessor processor = 
        new AutoRenewMembershipDataProcessor();
    Database.executeBatch(processor);
    Test.stopTest(); // Forces async to complete
    
    // Verify results
    List<Membership__c> renewed = [
        SELECT Id FROM Membership__c WHERE Status__c = 'Renewed'
    ];
    Assert.areEqual(expectedCount, renewed.size());
}
```

### Testing @future Methods

```apex
@IsTest
static void testFutureMethod() {
    Test.startTest();
    MyClass.futureMethod(recordIds);
    Test.stopTest(); // Forces future to complete
    
    // Verify
}
```

## Bulk Testing

> [!IMPORTANT]
> **Always test with 200+ records**

```apex
@IsTest
static void testBulkOperation() {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 200; i++) {
        accounts.add(new Account(Name = 'Test ' + i));
    }
    insert accounts;
    
    Test.startTest();
    // Bulk operation
    Test.stopTest();
    
    // Bulk verification
}
```

## Test Naming Convention

```apex
// Pattern: test<MethodName>_<Scenario>_<ExpectedResult>

@IsTest
static void testRenewMembership_WithValidData_CreatesInvoice() { }

@IsTest
static void testRenewMembership_WithExpiredMembership_ThrowsError() { }

@IsTest
static void testRenewMembership_BulkOperation_Processes200Records() { }
```

## Assertions

```apex
// Equality
Assert.areEqual(expected, actual, 'Message');
Assert.areNotEqual(notExpected, actual, 'Message');


// Null checks
Assert.areNotEqual(null, result, 'Message');

// Collection size
Assert.areEqual(5, results.size(), 'Message');

// Exception testing
try {
    // Code that should throw
    Assert.areEqual(false, 'Expected value', 'Message');
} catch (ExpectedException e) {
    Assert.areEqual(false, 'Expected value', 'Message');
}
```

## Coverage Requirements

> [!IMPORTANT]
> - **85% per class** minimum
> - **100% for global methods** (via DML tests)
> - **Schema tests** for all custom fields

## Do's and Don'ts

### ✅ DO

- Write mock tests co-located with classes
- Write DML tests for global methods in `unpackaged/test_config/test_classes/service_test/`
- Write schema tests in `unpackaged/test_config/test_classes/schema_test/`
- Test bulk operations (200+ records)
- Use test data factories
- Test positive and negative scenarios
- Use `@TestSetup` for shared data
- Meaningful assertion messages

### ❌ DON'T

- Use `@SeeAllData=true` (except platform queries)
- Hard-code IDs
- Depend on org data
- Skip global method DML tests
- Skip schema validation tests
- Test only happy paths
- Create unnecessary test data

## Element-Specific Conventions

1. **Mock Test Location**: `force-app/<layer>/test/classes/`
2. **DML Test Location**: `unpackaged/test_config/test_classes/service_test/` or `trigger_test/`
3. **Schema Test Location**: `unpackaged/test_config/test_classes/schema_test/`
4. **Naming**: `<ClassName>Test.cls`

## Interactions with Other Skills

### Tests All
- apex-selector-pattern
- apex-service-pattern
- apex-trigger-framework
- apex-data-processor
- lwc-development (Apex controllers)

### Uses
- ApexMocks framework
- Test data factories
- **apex-testing-mocking** — MockApexClasses selector stub pattern

### References
- **salesforce-architecture** - Testing requirements
- **apex-development** - Code being tested

## Quick Reference

| Test Type | Location | Purpose | Requirement |
|-----------|----------|---------|-------------|
| **Mock** | `force-app/*/test/` | Unit tests | 85%+ per class |
| **DML** | `unpackaged/.../service_test/` | Global methods | 100% global methods |
| **Schema** | `unpackaged/.../schema_test/` | Field validation | All custom fields |
