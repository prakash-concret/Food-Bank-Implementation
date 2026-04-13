---
name: apex-data-processor
description: Implementation guide for Data Processor pattern in Element AMS. Use when creating classes that perform complex data transformations, batch operations, or scheduled data processing. Covers the DataProcessor base class, scheduling patterns, and integration with services.
---

# Apex Data Processor Pattern

## Purpose

Data Processors handle **complex data transformations and scheduled operations** in Element AMS. They extend the `DataProcessor` base class and are used for operations like auto-renewals, segment updates, write-offs, and journal entry creation.

## When to Use This Skill

- Implementing scheduled data operations
- Performing complex data transformations
- Processing large datasets in batches
- Automating recurring business processes (renewals, credits, write-offs)

## Core Architecture

```
DataProcessor (Base Class)
    ↓
Specific Data Processor (e.g., AutoRenewMembershipDataProcessor)
    ↓
Scheduled via CumulusCI or Apex Scheduler
```

## Basic Implementation

```apex
/**
 * @description Processes automatic membership renewals
 * @group Data Processors
 */
public class AutoRenewMembershipDataProcessor extends DataProcessor {
    
    public override void execute(Database.BatchableContext bc, List<SObject> scope) {
        // Cast scope to specific type
        List<Membership__c> memberships = (List<Membership__c>) scope;
        
        // Collect IDs for processing
        Set<Id> membershipIds = new Set<Id>();
        for (Membership__c membership : memberships) {
            if (shouldRenew(membership)) {
                membershipIds.add(membership.Id);
            }
        }
        
        // Delegate to service
        if (!membershipIds.isEmpty()) {
            MembershipService.getInstance()
                .renewMemberships(membershipIds);
        }
    }
    
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        // Define records to process
        Date renewalThreshold = Date.today().addDays(30);
        
        return Database.getQueryLocator([
            SELECT Id, Name, End_Date__c, Auto_Renew__c, 
                   Contact__c, Product__c, Account__c
            FROM Membership__c
            WHERE Auto_Renew__c = true
            AND End_Date__c <= :renewalThreshold
            AND Status__c = 'Active'
        ]);
    }
    
    public override void finish(Database.BatchableContext bc) {
        // Optional: Send notification email
        System.debug('Auto renewal processing complete');
    }
    
    private Boolean shouldRenew(Membership__c membership) {
        // Business logic for renewal eligibility
        return membership.Auto_Renew__c && 
               membership.End_Date__c <= Date.today().addDays(30);
    }
}
```

## DataProcessor Base Class Methods

### Required Methods

```apex
// Define scope of records to process
public override Database.QueryLocator start(Database.BatchableContext bc)

// Process each batch of records
public override void execute(Database.BatchableContext bc, List<SObject> scope)

// Optional: Post-processing after all batches
public override void finish(Database.BatchableContext bc)
```

## Scheduling Data Processors

### Via CumulusCI Flow

```yaml
# In cumulusci.yml
schedule_auto_renew_membership:
    description: Schedule auto renew memberships everyday at 1 AM
    steps:
        1:
            task: execute_anon
            options:
                path: unpackaged/config/anonymous-apex/ScheduleApexAnonymous.cls
                apex: scheduleDataProcessorApex('AutoRenewMemberships', '0 0 1 * * ? *', 'AutoRenewMembershipDataProcessor');
```

### Via Apex

```apex
// Schedule to run daily at 1 AM
String cronExp = '0 0 1 * * ? *';
String jobName = 'AutoRenewMemberships';

// Using helper method
ScheduleDataProcessor.schedule(
    jobName,
    cronExp,
    new AutoRenewMembershipDataProcessor()
);
```

## Common Data Processor Patterns

### Journal Entry Creation

```apex
public class InvoiceActivityJournalEntryDataProcessor extends DataProcessor {
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Sales_Invoice__c, Amount__c, Type__c
            FROM Invoice_Activity__c
            WHERE Journal_Entry_Created__c = false
            AND Status__c = 'Finalized'
        ]);
    }
    
    public override void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Invoice_Activity__c> activities = 
            (List<Invoice_Activity__c>) scope;
        
        // Delegate to service
        JournalEntryService.getInstance()
            .createJournalEntriesForActivities(
                new Map<Id, Invoice_Activity__c>(activities).keySet()
            );
    }
}
```

### Segment Updates

```apex
public class AutoUpdateSegmentDataProcessor extends DataProcessor {
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Criteria__c
            FROM Segment__c
            WHERE Auto_Update__c = true
            AND Active__c = true
        ]);
    }
    
    public override void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Segment__c> segments = (List<Segment__c>) scope;
        
        for (Segment__c segment : segments) {
            SegmentService.getInstance()
                .updateSegmentMembers(segment.Id);
        }
    }
}
```

### Write-Off Processing

```apex
public class AutoWriteOffDataProcessor extends DataProcessor {
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        Date writeOffThreshold = Date.today().addDays(-90);
        
        return Database.getQueryLocator([
            SELECT Id, Balance_Due__c, Account__c, Invoice_Date__c
            FROM Sales_Invoice__c
            WHERE Balance_Due__c > 0
            AND Invoice_Date__c <= :writeOffThreshold
            AND Status__c != 'Written Off'
        ]);
    }
    
    public override void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Sales_Invoice__c> invoices = (List<Sales_Invoice__c>) scope;
        
        Set<Id> invoiceIds = new Map<Id, Sales_Invoice__c>(invoices).keySet();
        
        WriteOffService.getInstance()
            .writeOffInvoices(invoiceIds);
    }
}
```

## Integration with Services

> [!IMPORTANT]
> Data Processors should delegate business logic to Services

```apex
// CORRECT
public override void execute(Database.BatchableContext bc, List<SObject> scope) {
    Set<Id> ids = new Map<Id, SObject>(scope).keySet();
    MyService.getInstance().processRecords(ids);
}

// WRONG - Don't put business logic in Data Processor
public override void execute(Database.BatchableContext bc, List<SObject> scope) {
    // Complex business logic here
    // DML operations here
}
```

## Batch Size Considerations

```apex
// Execute with specific batch size
Database.executeBatch(new AutoRenewMembershipDataProcessor(), 50);

// Default batch size is 200
Database.executeBatch(new AutoRenewMembershipDataProcessor());
```

## Error Handling

```apex
public override void execute(Database.BatchableContext bc, List<SObject> scope) {
    try {
        // Processing logic
        Set<Id> ids = new Map<Id, SObject>(scope).keySet();
        MyService.getInstance().processRecords(ids);
    } catch (Exception e) {
        // Log error
        Logger.error('Data Processor Error', e)
            .addTag('DataProcessor')
            .addTag('AutoRenewal');
        Logger.saveLog();
        
        // Don't rethrow - allow batch to continue
    }
}
```

## Elements-Specific Data Processors

### Auto Credit Memo

```apex
public class AutoCreditMemoDataProcessor extends DataProcessor {
    // Creates credits for eligible customers weekly
}
```

### Auto Pay Installments

```apex
public class AutoPayInstallmentDataProcessor extends DataProcessor {
    // Processes automatic installment payments
}
```

### Membership Path

```apex
public class MembershipPathDataProcessor extends DataProcessor {
    // Advances members through membership paths
}
```

## Interactions with Other Skills

### Uses
- **apex-service-pattern** - Delegates business logic
- **apex-selector-pattern** - May use for complex queries
- **logger-framework** - Logs processing results

### Called By
- **cumulusci-devops** - Deployed and scheduled via flows

## Do's and Don'ts

### ✅ DO

- Extend `DataProcessor` base class
- Delegate business logic to Services
- Perform DML using Services with UnitOfWork
- Handle bulk operations (200+ records per batch)
- Log errors and completion
- Use appropriate batch sizes
- Schedule via CumulusCI flows
- Test with realistic data volumes

### ❌ DON'T

- Put complex business logic in Data Processors
- Perform DML directly (use Services with UnitOfWork)
- Query inside loops
- Hardcode business rules
- Skip error handling
- Forget to test bulk scenarios

## Testing

```apex
@IsTest
private class AutoRenewMembershipDataProcessorTest {
    @IsTest
    static void testBatchExecution() {
        // Setup test data
        List<Membership__c> memberships = TestDataFactory.createMemberships(200);
        insert memberships;
        
        // Execute data processor
        Test.startTest();
        Database.executeBatch(new AutoRenewMembershipDataProcessor());
        Test.stopTest();
        
        // Verify results
        List<Membership__c> renewals = [
            SELECT Id FROM Membership__c 
            WHERE Renewed_From__c != null
        ];
        System.assertEquals(200, renewals.size());
    }
}
```

## Element-Specific Conventions

1. **Naming**: `<Purpose>DataProcessor.cls`
2. **Location**: `force-app/data-processor/main/classes/`
3. **Test Location**: `force-app/data-processor/test/classes/`
4. **Scheduling**: Via CumulusCI flows in `cumulusci.yml`

Remember: Claude is capable of extraordinary creative work. Don't hold back, show what can truly be created when thinking outside the box and committing fully to a distinctive vision.

