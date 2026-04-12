---
name: apex-trigger-framework
description: Metadata Trigger Action Framework implementation for Element AMS. Use when creating triggers, adding trigger logic, configuring trigger actions via custom metadata, or implementing bypass mechanisms. Covers one-trigger-per-object pattern, TriggerAction interfaces, metadata configuration, execution order, and service integration.
---

# Apex Trigger Framework

## Purpose

Element uses the **Metadata Trigger Action Framework** for all trigger logic. This provides configuration-driven triggers managed via `Trigger_Action__mdt`, enabling flexible trigger management without code deployments.

## When to Use

- Creating new triggers
- Adding trigger logic for insert/update/delete/undelete
- Configuring trigger execution order
- Implementing bypass mechanisms
- Managing trigger recursion

## One Trigger Per Object

**Pattern**: Each SObject has exactly ONE trigger that delegates to `MetadataTriggerHandler`.

```apex
/**
 * @description Trigger for Membership__c object
 */
trigger MembershipTrigger on Membership__c (
    before insert, after insert,
    before update, after update,
    before delete, after delete,
    after undelete
) {
    new MetadataTriggerHandler().run();
}
```

> [!IMPORTANT]
> ALL logic goes in **Action Classes**, NOT in the trigger itself.

## Trigger Action Classes

### Action Class Pattern

```apex
/**
 * @description Validates membership dates before insert/update
 * @group Trigger Actions
 */
public class TA_Membership_ValidateDates implements
    TriggerAction.BeforeInsert,
    Trigger Action.BeforeUpdate {
    
    public void beforeInsert(List<Membership__c> newList) {
        validateDates(newList);
    }
    
    public void beforeUpdate(
        List<Membership__c> newList,
        List<Membership__c> oldList
    ) {
        validateDates(newList);
    }
    
    private void validateDates(List<Membership__c> memberships) {
        for (Membership__c m : memberships) {
            if (m.End_Date__c <= m.Start_Date__c) {
                m.addError('End date must be after start date');
            }
        }
    }
}
```

### Available Interfaces

```apex
TriggerAction.BeforeInsert    // beforeInsert(List<SObject> newList)
TriggerAction.AfterInsert     // afterInsert(List<SObject> newList)
TriggerAction.BeforeUpdate    // beforeUpdate(List<SObject> newList, List<SObject> oldList)
TriggerAction.AfterUpdate     // afterUpdate(List<SObject> newList, List<SObject> oldList)
TriggerAction.BeforeDelete    // beforeDelete(List<SObject> oldList)
TriggerAction.AfterDelete     // afterDelete(List<SObject> oldList)
TriggerAction.AfterUndelete   // afterUndelete(List<SObject> newList)
```

## Custom Metadata Configuration

### Trigger_Action__mdt Record

Configure each action via Custom Metadata:

| Field | Example Value | Description |
|-------|---------------|-------------|
| **Label** | Membership Validate Dates | Human-readable name |
| **Apex_Class_Name__c** | TA_Membership_ValidateDates | Action class name |
| **Object__c** | element__Membership__c | Target SObject |
| **Order__c** | 10 | Execution order (lower = earlier) |
| **Before_Insert__c** | ☑ | Execute on before insert |
| **Before_Update__c** | ☑ | Execute on before update |
| **Bypass_Execution__c** | ☐ | Not bypassed by default |

### Execution Order Strategy

Actions execute in **ascending Order__c**:

- **10-19**: Validation
- **20-29**: Field defaulting
- **30-39**: Service calls (DML operations)
- **100+**: Logging and auditing

## Service Integration

> [!IMPORTANT]
> Delegate complex logic to **Services**, not Action classes

```apex
/**
 * @description Creates invoices for new memberships
 * @group Trigger Actions
 */
public class TA_Membership_CreateInvoice implements TriggerAction.AfterInsert {
    
    public void afterInsert(List<Membership__c> newList) {
        // Collect eligible IDs
        Set<Id> membershipIds = new Set<Id>();
        for (Membership__c m : newList) {
            if (m.Create_Invoice__c) {
                membershipIds.add(m.Id);
            }
        }
        
        // Delegate to Service
        if (!membershipIds.isEmpty()) {
            MembershipService.getInstance()
                .createInvoicesForMemberships(membershipIds);
        }
    }
}
```

**Use:** `apex-service-pattern` for complex business logic

## Bypass Mechanisms

### Bypass Specific Action

```apex
// In test or data load
MetadataTriggerHandler.bypass('TA_Membership_CreateInvoice');

// Your operations
insert memberships;

// Clear bypass
MetadataTriggerHandler.clearBypass('TA_Membership_CreateInvoice');
```

### Bypass All Triggers for SObject

```apex
TriggerBase.bypass('Membership__c');

// Your operations

TriggerBase.clearBypass('Membership__c');
```

### Clear All Bypasses

```apex
MetadataTriggerHandler.clearAllBypasses();
```

## Bulk Patterns

**Always handle bulk operations** (200+ records):

```apex
public class TA_Invoice_UpdateAccount implements TriggerAction.AfterUpdate {
    
    public void afterUpdate(
        List<Sales_Invoice__c> newList,
        List<Sales_Invoice__c> oldList
    ) {
        // Build context map
        Map<Id, Sales_Invoice__c> oldMap = new Map<Id, Sales_Invoice__c>(oldList);
        
        // Collect affected accounts
        Set<Id> accountIds = new Set<Id>();
        for (Sales_Invoice__c invoice : newList) {
            Sales_Invoice__c oldInvoice = oldMap.get(invoice.Id);
            if (invoice.Status__c != oldInvoice.Status__c) {
                accountIds.add(invoice.Account__c);
            }
        }
        
        // Delegate bulk processing to Service
        if (!accountIds.isEmpty()) {
            AccountService.getInstance().updateInvoiceStatus(accountIds);
        }
    }
}
```

## DML Testing

> [!IMPORTANT]
> **ALL trigger actions** MUST have DML tests in:
> `unpackaged/test_config/test_classes/trigger_test/`

### DML Test Example

```apex
// Location: unpackaged/test_config/test_classes/trigger_test/TA_Membership_ValidateDatesTest.cls
@IsTest
private class TA_Membership_ValidateDatesTest {
    
    @IsTest
    static void testInvalidDates_ThrowsError() {
        Product__c product = new Product__c(Name = 'Test');
        insert product;
        
        Membership__c membership = new Membership__c(
            Name = 'Test',
            Product__c = product.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(-1) // Invalid!
        );
        
        Test.startTest();
        try {
            insert membership;
            System.assert(false, 'Should have thrown error');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('End date must be after start date')
            );
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidDates_Success() {
        Product__c product = new Product__c(Name = 'Test');
        insert product;
        
        Membership__c membership = new Membership__c(
            Name = 'Test',
            Product__c = product.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(12)
        );
        
        Test.startTest();
        insert membership;
        Test.stopTest();
        
        System.assertNotEquals(null, membership.Id);
    }
}
```

**Use:** `apex-testing` skill for comprehensive test patterns

## Common Patterns

### Field Defaulting

```apex
public class TA_Membership_DefaultFields implements TriggerAction.BeforeInsert {
    
    public void beforeInsert(List<Membership__c> newList) {
        for (Membership__c m : newList) {
            if (m.Status__c == null) {
                m.Status__c = 'Pending';
            }
            if (m.Created_Via__c == null) {
                m.Created_Via__c = 'Manual';
            }
        }
    }
}
```

### Prevent Deletion

```apex
public class TA_Batch_PreventDelete implements TriggerAction.BeforeDelete {
    
    public void beforeDelete(List<Batch__c> oldList) {
        for (Batch__c batch : oldList) {
            if (batch.Closed__c) {
                batch.addError('Cannot delete closed batch');
            }
        }
    }
}
```

### Query Related Records

```apex
public class TA_Contact_UpdateAccount implements TriggerAction.AfterUpdate {
    
    public void afterUpdate(
        List<Contact> newList,
        List<Contact> oldList
    ) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Contact> oldMap = new Map<Id, Contact>(oldList);
        
        for (Contact c : newList) {
            Contact oldContact = oldMap.get(c.Id);
            if (c.Primary_Contact__c != oldContact.Primary_Contact__c) {
                accountIds.add(c.AccountId);
            }
        }
        
        if (!accountIds.isEmpty()) {
            AccountService.getInstance().updatePrimaryContact(accountIds);
        }
    }
}
```

## Do's and Don'ts

### ✅ DO

- Create one trigger per SObject
- One action class per logical operation
- Configure via Trigger_Action__mdt
- Write DML tests in `unpackaged/test_config/test_classes/trigger_test/`
- Delegate to Services for complex logic
- Handle bulk operations (200+ records)
- Use bypass for data loads and testing

### ❌ DON'T

- Put logic in trigger files
- Mix multiple unrelated operations in one action
- Perform SOQL/DML in action classes (use Services)
- Forget metadata configuration
- Hardcode execution order in code
- Ignore bulk patterns

## Element-Specific Conventions

1. **Naming**: `TA_<SObject>_<Operation>.cls`
2. **Location**: `force-app/trigger/main/classes/`
3. **Metadata**: Configure in Setup → Custom Metadata → Trigger Action
4. **Test Location**: `unpackaged/test_config/test_classes/trigger_test/`

## Interactions with Other Skills

### Uses
- **apex-service-pattern** - Delegate business logic to Services
- **metadata-configuration** - Trigger_Action__mdt setup

### Called By
- Salesforce Platform (DML operations)

### References
- **salesforce-architecture** - Trigger architecture patterns
- **apex-development** - Coding standards
- **apex-testing** - DML test patterns

## Quick Reference

| Task | Action |
|------|--------|
| New trigger | One per object, delegate to `MetadataTriggerHandler` |
| New logic | Create Action class, configure in Trigger_Action__mdt |
| Execution order | Set Order__c (10=validation, 20=defaults, 30=services) |
| Complex logic | Delegate to Service |
| Testing | DML tests in `unpackaged/test_config/test_classes/trigger_test/` |
| Data loads | Use bypass mechanisms |
