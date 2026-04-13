---
name: apex-testing-mocking
description: Element AMS mocking strategy using MockApexClasses and fflib_ApexMocks. Use when writing test classes that need to mock Selectors, Services, or other dependencies. Covers the MockApexClasses utility, the selector chaining stub pattern, and how to add new selector mocks.
---

# Apex Testing — Mocking with MockApexClasses

## Purpose

Element uses a **centralised mocking utility class** (`MockApexClasses`) to avoid duplicating selector stub boilerplate across every test class. All selector mocks must be added to `MockApexClasses` and consumed from there — never inline in individual test classes.

## Location

```
force-app/services/test/classes/MockApexClasses.cls
```

## Why MockApexClasses Exists

Element selectors use a fluent chain API:

```apex
CredentialSelector.getInstance()
    .selectFields(fields)
    .setCondition('Id = :{0}', new List<Object>{ id })
    .setLimit(10)
    .getData();
```

Each chained method must be individually stubbed to return the selector mock itself, otherwise fflib_ApexMocks breaks the chain and throws a null pointer. `MockApexClasses` centralises this boilerplate so every test class gets consistent, correct mocks with a single call.

## Pattern for Adding a New Selector Mock

Every new Selector that needs to be mocked in tests **must** get a method added to `MockApexClasses`. Follow this template exactly:

```apex
/**
 * @description Mocks the behavior of the <SObjectName>Selector class for testing purposes.
 * @author Element
 * @param mocks
 * @param <sObjectName>List
 **/
public static void mock<SObjectName>Selector(fflib_ApexMocks mocks, List<SObject__c> <sObjectName>List) {
    // 1. Create the mock and assign to the selector's static instance field
    <SObjectName>Selector.<selectorStaticField> = (<SObjectName>Selector) mocks.mock(<SObjectName>Selector.class);

    // 2. Stub every chain method to return the mock itself
    mocks.when(<SObjectName>Selector.<selectorStaticField>.selectFields(
            (List<Schema.SObjectField>) fflib_Match.anyObject()))
        .thenReturn(<SObjectName>Selector.<selectorStaticField>);

    mocks.when(<SObjectName>Selector.<selectorStaticField>.selectField(
            (Schema.SObjectField) fflib_Match.anyObject()))
        .thenReturn(<SObjectName>Selector.<selectorStaticField>);

    mocks.when(<SObjectName>Selector.<selectorStaticField>.setCondition(
            (String) fflib_Match.anyString(),
            (List<Object>) fflib_Match.anyObject()))
        .thenReturn(<SObjectName>Selector.<selectorStaticField>);

    mocks.when(<SObjectName>Selector.<selectorStaticField>.setCondition(
            (String) fflib_Match.anyString()))
        .thenReturn(<SObjectName>Selector.<selectorStaticField>);

    mocks.when(<SObjectName>Selector.<selectorStaticField>.setLimit(
            (Integer) fflib_Match.anyObject()))
        .thenReturn(<SObjectName>Selector.<selectorStaticField>);

    mocks.when(<SObjectName>Selector.<selectorStaticField>.setOffset(
            (Integer) fflib_Match.anyObject()))
        .thenReturn(<SObjectName>Selector.<selectorStaticField>);

    mocks.when(<SObjectName>Selector.<selectorStaticField>.setOrdering(
            (SObjectField) fflib_Match.anyObject(),
            (fflib_QueryFactory.SortOrder) fflib_Match.anyObject(),
            (Boolean) fflib_Match.anyObject()))
        .thenReturn(<SObjectName>Selector.<selectorStaticField>);

    mocks.when(<SObjectName>Selector.<selectorStaticField>.setOrdering(
            (String) fflib_Match.anyString(),
            (fflib_QueryFactory.SortOrder) fflib_Match.anyObject(),
            (Boolean) fflib_Match.anyObject()))
        .thenReturn(<SObjectName>Selector.<selectorStaticField>);

    mocks.when(<SObjectName>Selector.<selectorStaticField>.configureQueryParentFields(
            (List<Schema.SObjectField>) fflib_Match.anyObject(),
            (String) fflib_Match.anyObject()))
        .thenReturn(<SObjectName>Selector.<selectorStaticField>);

    mocks.when(<SObjectName>Selector.<selectorStaticField>.setSystemAccessMode())
        .thenReturn(<SObjectName>Selector.<selectorStaticField>);

    mocks.when(<SObjectName>Selector.<selectorStaticField>.setWithoutSharing())
        .thenReturn(<SObjectName>Selector.<selectorStaticField>);

    // 3. Stub getData() to return the provided test data
    mocks.when(<SObjectName>Selector.<selectorStaticField>.getData())
        .thenReturn(<sObjectName>List);
}
```

Only stub the chain methods your selector actually uses. Include all of them if the selector's usage may vary across tests.

## Real Example — CredentialSelector

```apex
public static void mockCredentialSelector(fflib_ApexMocks mocks, List<Credential__c> credentialList) {
    CredentialSelector.credentialSelectorObj = (CredentialSelector) mocks.mock(CredentialSelector.class);

    mocks.when(CredentialSelector.credentialSelectorObj.selectFields(
            (List<Schema.SObjectField>) fflib_Match.anyObject()))
        .thenReturn(CredentialSelector.credentialSelectorObj);

    mocks.when(CredentialSelector.credentialSelectorObj.configureQueryParentFields(
            (List<Schema.SObjectField>) fflib_Match.anyObject(),
            (String) fflib_Match.anyObject()))
        .thenReturn(CredentialSelector.credentialSelectorObj);

    mocks.when(CredentialSelector.credentialSelectorObj.setCondition(
            (String) fflib_Match.anyString(),
            (List<Object>) fflib_Match.anyObject()))
        .thenReturn(CredentialSelector.credentialSelectorObj);

    mocks.when(CredentialSelector.credentialSelectorObj.setLimit(
            (Integer) fflib_Match.anyObject()))
        .thenReturn(CredentialSelector.credentialSelectorObj);

    mocks.when(CredentialSelector.credentialSelectorObj.setOffset(
            (Integer) fflib_Match.anyObject()))
        .thenReturn(CredentialSelector.credentialSelectorObj);

    mocks.when(CredentialSelector.credentialSelectorObj.setOrdering(
            (SObjectField) fflib_Match.anyObject(),
            (fflib_QueryFactory.SortOrder) fflib_Match.anyObject(),
            (Boolean) fflib_Match.anyObject()))
        .thenReturn(CredentialSelector.credentialSelectorObj);

    mocks.when(CredentialSelector.credentialSelectorObj.getData())
        .thenReturn(credentialList);
}
```

## How to Use MockApexClasses in a Test

```apex
@IsTest
static void fetchCredentialDetailsValidDataTest() {
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    // Mock services
    CryptoService.cryptoServiceObj = (CryptoService) mocks.mock(CryptoService.class);
    SettingService.settingServiceObj = (SettingService) mocks.mock(SettingService.class);

    List<Credential__c> credentialList = TestDataFactory.mockCredentials(3);

    mocks.startStubbing();
    mocks.when(CryptoService.cryptoServiceObj.doEncrypt((String) fflib_Match.anyString()))
        .thenReturn(new ServiceResponse('encrypted'));
    mocks.when(SettingService.settingServiceObj.getElementSetting((String) fflib_Match.anyString()))
        .thenReturn(TestDataFactory.mockElementCustomSettings(1)[0]);

    // ✅ Use MockApexClasses — never stub the selector chain inline
    MockApexClasses.mockCredentialSelector(mocks, credentialList);
    MockApexClasses.mockRosterButtonSelector(mocks, new List<Roster_Button__mdt>());
    mocks.stopStubbing();

    Test.startTest();
    ServiceResponse response = CredentialDetailService.getInstance().fetchCredentialDetails(request);
    Test.stopTest();

    // Assertions...
}
```

## Exception Testing — Inline Stub Is Acceptable

When testing that a specific method throws, it is acceptable to stub that one method inline rather than via `MockApexClasses`, because you need to override the `getData()` return with `thenThrow`:

```apex
@IsTest
static void fetchCredentialDetailsWithExceptionTest() {
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    CredentialSelector.credentialSelectorObj = (CredentialSelector) mocks.mock(CredentialSelector.class);

    mocks.startStubbing();
    mocks.when(CredentialSelector.credentialSelectorObj.configureQueryParentFields(
            (List<Schema.SObjectField>) fflib_Match.anyObject(),
            (String) fflib_Match.anyString()))
        .thenThrow(new QueryException('Internal Salesforce.com Error'));
    mocks.stopStubbing();

    Test.startTest();
    ServiceResponse response = CredentialDetailService.getInstance().fetchCredentialDetails(request);
    Test.stopTest();

    Assert.areEqual('Internal Salesforce.com Error', response.error.message, '...');
    Assert.isNull(response.data, '...');
}
```

## Setting Read-Only and Roll-Up Summary Fields in Test Data

Roll-up summary fields and formula fields are **not writable** in Apex. Direct assignment throws a compile-time error: `Field is not writeable`. Use `fflib_ApexMocksUtils.setReadOnlyFields` instead:

```apex
credentialRequirements[i] = (Credential_Requirement__c) fflib_ApexMocksUtils.setReadOnlyFields(
    credentialRequirements[i],
    Credential_Requirement__c.class,
    new Map<SObjectField, Object>{
        Credential_Requirement__c.Credential_Requirement_Group__c => credRequirementGroups[i].Id,
        Credential_Requirement__c.Completed_Mandatory_Requirements__c => 3,
        Credential_Requirement__c.Total_Mandatory_Requirements__c => 3
    }
);
```

- Regular writable fields (checkboxes, text, lookup IDs) can still be assigned directly before or after this call.
- Always reassign the result back to the record variable — `setReadOnlyFields` returns a new instance.
- This applies to **any** field that produces a "Field is not writeable" error: roll-up summaries, formula fields, and system fields.

## Rules

### ✅ DO

- Add a `mock<SObjectName>Selector` method to `MockApexClasses` for every new Selector
- Call `MockApexClasses.mock*` inside `mocks.startStubbing()` / `mocks.stopStubbing()` blocks
- Stub all chain methods that the selector uses (`.selectFields`, `.setCondition`, `.setLimit`, `.setOffset`, `.setOrdering`, `.configureQueryParentFields`, `.setSystemAccessMode`, `.setWithoutSharing`, `.getData`)
- Use `fflib_Match.anyObject()` / `fflib_Match.anyString()` — never match on specific values in `MockApexClasses`
- Use `fflib_ApexMocksUtils.setReadOnlyFields` for roll-up summary fields, formula fields, or any read-only field in test data

### ❌ DON'T

- Inline the full selector chain stub in individual test classes for happy-path tests
- Create a second mock for the same selector in different test methods — reuse `MockApexClasses`
- Forget to assign the mock to the selector's static instance field before stubbing
- Stub `getData()` with `thenReturn` inside `MockApexClasses` — it must accept the list as a parameter so callers control the data
- Directly assign roll-up summary or formula fields — this causes a compile-time "Field is not writeable" error

## Interactions with Other Skills

### Used By
- **apex-testing** — references this skill for selector mocking
- All test classes under `force-app/*/test/classes/`

### Depends On
- **apex-selector-pattern** — selectors being mocked
- fflib_ApexMocks framework
