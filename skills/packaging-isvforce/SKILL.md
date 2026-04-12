---
name: packaging-isvforce
description: Second-generation packaging (2GP) for Element AMS ISV managed package. Use when creating package versions, managing namespace (element), handling dependencies, maintaining backward compatibility, or preparing for AppExchange distribution. Covers sfdx-project.json configuration, version creation/promotion, installation scripts, and security review preparation.
---

# ISV Package Management (2GP)

## Purpose

Manage Element AMS as a **Salesforce ISV managed package** using second-generation packaging (2GP) with proper versioning, namespace handling, and subscriber compatibility.

## When to Use

- Creating or promoting package versions
- Managing package dependencies
- Handling namespace in code
- Preparing for AppExchange submission
- Managing upgrades and versioning

## sfdx-project.json Configuration

```json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true,
      "package": "Element AMS",
      "versionName": "Spring '25",
      "versionNumber": "1.24.0.NEXT"
    },
    {
      "path": "unpackaged"
    }
  ],
  "name": "element",
  "namespace": "element",
  "sourceApiVersion": "63.0"
}
```

## Namespace Handling

### Schema References (Namespace-Aware)

```apex
// ✅ CORRECT - Namespace-aware
Product__c.Name.getDescribe();
Schema.SObjectType.Product__c.fields.Active__c;

// ❌ WRONG - Hardcoded namespace
String fieldName = 'element__Product__c';
```

### Dynamic Namespace

```apex
public class NamespaceUtil {
    public static final String NAMESPACE = 
        NamespaceUtil.class.getName()
            .substringBefore('NamespaceUtil')
            .removeEnd('.');
    
    public static String prefixNamespace(String name) {
        return String.isNotBlank(NAMESPACE) 
            ? NAMESPACE + '__' + name 
            : name;
    }
}
```

## Version Management

### Version Numbering

Format: `MAJOR.MINOR.PATCH.BUILD`

- **MAJOR** (1.x.x.x): Breaking changes, major features
- **MINOR** (x.24.x.x): New features, backward compatible
- **PATCH** (x.x.0.x): Bug fixes
- **BUILD** (x.x.x.NEXT): Auto-incremented

### Creating Package Versions

```bash
# Create new version
sf package version create \
    --package "Element AMS" \
    --installation-key-bypass \
    --wait 30

# Promote to released
sf package version promote --package 04t...

# Install in test org
sf package install --package 04t... --wait 30
```

**Use:** `cumulusci-devops` for automated flows

## Backward Compatibility

### Global API Contracts

```apex
/**
 * Global methods CANNOT be removed or have signatures changed
 */
global class MembershipService {
    
    /**
     * @deprecated Use renewMembershipsV2 instead
     * Deprecated in version 1.20.0
     */
    @Deprecated
    global static void renewMemberships(List<Id> ids) {
        // Maintain old signature, delegate to new implementation
        renewMembershipsV2(new Set<Id>(ids));
    }
    
    /**
     * @description Improved renewal process
     * @since 1.20.0
     */
    global static Map<Id, Id> renewMembershipsV2(Set<Id> ids) {
        // New implementation
    }
}
```

### Deprecation Pattern

```apex
/**
 * @deprecated This method is deprecated as of version 1.20.
 * Use {@link NewClass#newMethod} instead.
 * Will be removed in version 2.0.
 */
@Deprecated
global static void oldMethod() {
    // Keep implementation for backward compatibility
}
```

## Package Structure

```
force-app/                  # Managed package components
├── apex-common/            # fflib framework
├── selector/               # Data access
├── services/               # Business logic
├── trigger/                # Trigger actions
├── trigger-framework/      # MetadataTriggerHandler
├── data-processor/         # Async operations
├── ui/                     # LWC components
├── base/                   # Metadata (objects, fields)
└── logger/                 # Nebula Logger

unpackaged/                 # Unmanaged extensions
├── config/                 # Org-specific configuration
├── test_config/            # DML and schema tests
│   └── test_classes/
│       ├── service_test/   # Global method tests
│       ├── trigger_test/   # Trigger action tests
│       └── schema_test/    # Field validation tests
└── post_install/           # Post-install scripts
```

## Custom Metadata Configuration

```apex
// Query namespace-aware
List<Community_Setting__mdt> settings = [
    SELECT Base_URL__c, Site_Name__c
    FROM Community_Setting__mdt
    WHERE Active__c = true
];

// Works with or without namespace
for (Community_Setting__mdt setting : settings) {
    String url = setting.Base_URL__c; // Auto-handles namespace
}
```

## Installation & Upgrade

### Post-Install Handler

```apex
global class ElementPostInstall implements InstallHandler {
    
    global void onInstall(InstallContext context) {
        if (context.isUpgrade()) {
            handleUpgrade(context.previousVersion());
        } else if (context.isPush()) {
            handlePush(context.previousVersion());
        } else {
            handleFreshInstall();
        }
    }
    
    private void handleUpgrade(Version prev) {
        // Migration logic for upgrades
        if (prev.compareTo (new Version(1, 20)) < 0) {
            // Migrate from pre-1.20
        }
    }
    
    private void handleFreshInstall() {
        // Initial setup for new installs
    }
    
    private void handlePush(Version prev) {
        // Handle push upgrades
    }
}
```

## Code Coverage Requirements

> [!IMPORTANT]
> **75% minimum** for package upload  
> **Element standard: 85%+** per class

```bash
# Run tests and check coverage
sf apex run test --wait 30 --code-coverage --result-format human

# View coverage
sf apex get test --test-run-id 707...
```

## Security Review Preparation

### Checklist

✅ **CRUD/FLS checks** - Use `fflib_SecurityUtils`  
✅ **Sharing documentation** - `@FalsePositive` for system mode  
✅ **No hardcoded credentials** - All config in Custom Metadata  
✅ **HTTPS only** - No HTTP remote sites  
✅ **Input validation** - Sanitize user input  
✅ **Error handling** - No sensitive data in errors  

### Remote Site Settings

```xml
<!-- In package -->
<RemoteS iteSetting>
    <fullName>External_API</fullName>
    <description>External API endpoint</description>
    <disableProtocolSecurity>false</disableProtocolSecurity>
    <isActive>true</isActive>
    <url>https://api.example.com</url>
</RemoteSiteSetting>
```

## Dependencies

### Package Dependencies

```json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true,
      "package": "Element AMS",
      "dependencies": [
        {
          "package": "Nebula Logger",
          "versionNumber": "4.12.0.LATEST"
        }
      ]
    }
  ]
}
```

## CI/CD Integration

**See:** `cumulusci-devops` skill for automation

```yaml
# .github/workflows/package.yml
name: Create Package Version
on:
  push:
    branches: [main]

jobs:
  package:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Create Package Version
        run: |
          sf package version create \
            --package "Element AMS" \
            --wait 30
```

## AppExchange Listing

### Package Metadata

- **Name**: Element AMS
- **Namespace**: element
- **Category**: Association Management
- **Pricing**: Per-user subscription
- **Support**: Standard support included

### Required Documentation

- Installation guide
- User guide
- Release notes
- API documentation (for global classes)
- Security architecture

## Do's and Don'ts

### ✅ DO

- Use Schema references (namespace-aware)
- Maintain backward compatibility for global APIs
- Document breaking changes in release notes
- Test package install/upgrade in scratch orgs
- Use Custom Metadata for configuration
- Version documentation with code
- Deprecate before removing

### ❌ DON'T

- Hardcode namespace in code
- Change global method signatures
- Remove global classes/methods
- Store credentials in code
- Reference org-specific IDs
- Skip upgrade testing
- Break subscriber integrations

## Element-Specific Conventions

1. **Namespace**: `element`
2. **Version Strategy**: Minor releases monthly, major annually
3. **Testing**: 85%+ coverage, all versions tested in scratch orgs
4. **Documentation**: API docs for all global methods
5. **Deprecation**: 2 major versions notice before removal

## Interactions with Other Skills

### Uses
- **cumulusci-devops** - Automated package creation and deployment
- **salesforce-architecture** - Package structure

### Referenced By
- All skills - Namespace and packaging considerations
- **apex-development** - Global method requirements
- **apex-testing** - Coverage requirements

## Quick Reference

| Task | Command/Pattern |
|------|-----------------|
| Create version | `sf package version create --package "Element AMS"` |
| Promote version | `sf package version promote --package 04t...` |
| Install package | `sf package install --package 04t...` |
| Namespace reference | Use `Schema.SObjectType` |
| Global method | Must maintain backward compatibility |
| Coverage | 75% minimum, 85%+ Element standard |
| Deprecation | `@Deprecated` + documentation |
