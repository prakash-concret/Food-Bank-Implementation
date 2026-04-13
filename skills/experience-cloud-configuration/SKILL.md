---
name: experience-cloud-configuration
description: Experience Cloud multi-community configuration for Element AMS. Use when setting up communities, configuring guest users, managing navigation, implementing community-specific features, and handling multi-tenant architecture.
---

# Experience Cloud Configuration

## Purpose

Configure and manage **multiple Experience Cloud communities** (Member Portal, Admin Portal, Chapter Portal) in Element AMS.

## Community Architecture

Element supports **three community types**:
1. **Element Member Portal** - End-user membership management
2. **Element Admin Portal** - Administrative functions
3. **Chapter Portal** - Chapter-specific features

## Configuration Files

### Community Creation (CumulusCI)

```yaml
create_community:
    options:
        template: Customer Service
        name: $project_config.project__custom__community_name
        timeout: 60000
        skip_existing: TRUE

create_admin_community:
    options:
        template: Customer Service
        name: $project_config.project__custom__admin_community_name
        url_path_prefix: admin
```

## Multi-Community Utilities

```javascript
// c/multiCommunityUtil
import { getCommunityData } from 'c/multiCommunityUtil';
import USER_ID from '@salesforce/user/Id';

const siteDetail = getCommunityData(USER_ID);
const accountId = siteDetail?.contextRecordId;
```

## Guest User Configuration

### Permission Sets

- **Element_Guest_User** - Basic guest access
- **St_Guest_User** - Stripe integration for guests

### Security

```yaml
assign_permission_sets:
    options:
        api_names:
            - Element_Guest_User
            - St_Guest_User
        user_alias: guest
```

## Navigation Configuration

Via Custom Metadata (`Navigation_Menu__mdt`, `Navigation_Menu_Items__mdt`):

```apex
List<Navigation_Menu__mdt> menus = [
    SELECT Label__c, Order__c
    FROM Navigation_Menu__mdt
    WHERE Community__c = :communityName
    ORDER BY Order__c
];
```

## Community-Specific LWC

```javascript
import { getCommunityData } from 'c/multiCommunityUtil';

connectedCallback() {
    this.currentSiteDetail = getCommunityData(USER_ID);
    this.communityName = this.currentSiteDetail?.name;
}
```

## Publishing

```bash
# Via CumulusCI
cci task run publish_community --org dev

# Via CLI
sf community publish --name "Element Member Portal"
```

## Do's and Don'ts

### ✅ DO
- Use community utilities for multi-community support
- Configure via Custom Metadata
- Assign proper guest user permissions
- Test as authenticated and guest users

### ❌ DON'T
- Hardcode community URLs
- Expose sensitive data to guest users
- Skip guest user security review

## Element Conventions

1. **Base URL Configuration**: Via `Community_Setting__mdt`
2. **Navigation**: Dynamic via Custom Metadata
3. **Branding**: Per-community themes
4. **Access**: Role-based via Permission Sets
