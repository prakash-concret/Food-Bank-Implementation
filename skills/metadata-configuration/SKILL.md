---
name: metadata-configuration
description: Custom Metadata Types configuration in Element AMS. Use when externalizing configuration, creating admin-configurable settings, managing environment-specific values, and implementing metadata-driven patterns.
---

# Metadata Configuration

## Purpose

Use **Custom Metadata Types** to externalize configuration and enable admin control without code changes.

## Custom Metadata Types in Element

### Community_Setting__mdt

Configure multi-community settings:

```apex
List<Community_Setting__mdt> settings = [
    SELECT Site_Name__c, Base_URL__c, Default_Account__c
    FROM Community_Setting__mdt
    WHERE Active__c = true
];
```

###  Payment_Settings__mdt

Payment gateway configuration:

```apex
Payment_Settings__mdt paymentConfig = [
    SELECT Stripe_Publishable_Key__c, Default_Payment_Method__c
    FROM Payment_Settings__mdt
    WHERE DeveloperName = 'Default'
    LIMIT 1
];
```

### Trigger_Action__mdt

Trigger framework configuration (see apex-trigger-framework skill).

## Creating Custom Metadata

```apex
// Query example
public static String getCommunityBaseURL(String siteName) {
    List<Community_Setting__mdt> settings = [
        SELECT Base_URL__c
        FROM Community_Setting__mdt
        WHERE Site_Name__c = :siteName
        LIMIT 1
    ];
    
    return settings.isEmpty() ? null : settings[0].Base_URL__c;
}
```

## Deployment

Via CumulusCI:

```yaml
deploy_cmts:
    description: Deploy Custom Metadata Types
    class_path: cumulusci.tasks.salesforce.Deploy
    options:
        path: unpackaged/config/cmts/customMetadata
```

## Do's and Don'ts

### ✅ DO
- Use for environment-specific config
- Make settings admin-configurable
- Deploy via CumulusCI flows
- Document metadata fields

### ❌ DON'T
- Store secrets in metadata
- Overuse (prefer Platform Cache for runtime config)
- Hardcode values that should be configurable

## Element Examples

1. **Community Settings** - Multi-community configuration
2. **Payment Settings** - Gateway credentials (encrypted)
3. **Navigation Menus** - Portal navigation structure
4. **Membership Paths** - Membership tier configurations
