---
name: logger-framework
description: Nebula Logger framework integration for Element AMS. Use when implementing logging, debugging, error tracking, and operational monitoring using the Logger framework.
---

# Logger Framework

## Purpose

Use **Nebula Logger** for comprehensive logging, error tracking, and debugging in Element AMS.

## Basic Usage

```apex
// Simple logging
Logger.info('Processing membership renewal');
Logger.saveLog();

// With details
Logger.info('Membership renewed', renewal)
    .addTag('Membership')
    .addTag('Renewal');
Logger.saveLog();

// Error logging
try {
    MembershipService.getInstance().renewMemberships(ids);
} catch (Exception e) {
    Logger.error('Renewal failed', e)
        .addTag('Error')
        .addTag('Membership');
    Logger.saveLog();
    throw e;
}
```

## Log Levels

```apex
Logger.finest('Very detailed debug info');
Logger.finer('Detailed debug info');
Logger.fine('Debug info');
Logger.debug('General debugging');
Logger.info('Informational');
Logger.warn('Warning');
Logger.error('Error occurred');
```

## Logging in Services

```apex
public class MembershipService {
    public Map<Id, Id> renewMemberships(Set<Id> membershipIds) {
        Logger.info('Starting membership renewals')
            .addTag('Service')
            .setField(Log__c.RecordCount__c, membershipIds.size());
        
        try {
            // Business logic
            Map<Id, Id> result = performRenewals(membershipIds);
            
            Logger.info('Renewals completed successfully')
                .setField(Log__c.RecordCount__c, result.size());
            
            return result;
        } catch (Exception e) {
            Logger.error('Renewal process failed', e);
            throw e;
        } finally {
            Logger.saveLog();
        }
    }
}
```

## Permission Sets

- **LoggerAdmin** - Full logger access
- **LoggerEndUser** - View logs
- **LoggerLogCreator** - Create logs

## Do's and Don'ts

### ✅ DO
- Use tags for categorization
- Log errors with context
- Call `saveLog()` to persist
- Use appropriate log levels

### ❌ DON'T
- Log sensitive data (PII, credentials)
- Spam logs excessively
- Skip `saveLog()` call

## Element Conventions

1. Always log Service errors
2. Use tags: '*Service', '*Selector', '*TriggerAction'
3. Include record counts for bulk operations
