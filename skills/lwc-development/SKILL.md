---
name: lwc-development
description: Lightning Web Component development for Element AMS. Use when building LWC components, implementing reactive patterns (@api/@wire/@track), integrating with Apex controllers, handling events, using Lightning Data Service, applying SLDS design system, or creating premium UI with frontend aesthetics. Covers component structure, communication patterns, and integration with frontend-design skill.
---

# LWC Development

## Purpose

Build **modern, accessible Lightning Web Components** for Element AMS following reactive patterns, SLDS design system, and premium frontend aesthetics.

## When to Use

- Creating LWC components
- Implementing wire services or reactive properties
- Handling events (parent-child, sibling communication)
- Integrating with Apex controllers
- Styling components with SLDS
- Building premium UI (see frontend-design)

## Component Structure

```javascript
import { LightningElement, api, track, wire } from 'lwc';
import { MessageContext, subscribe } from 'lightning/messageService';
import CHANNEL from '@salesforce/messageChannel/ChannelName__c';
import { getCommunityData } from 'c/multiCommunityUtil';

export default class MembershipCard extends LightningElement {
    @api recordId;             // Public property
    @track membership;         // Tracked state
    
    @wire(MessageContext)
    messageContext;
    
    connectedCallback() {
        this.loadData();
        this.subscribeToMessages();
    }
    
    loadData() {
        // Load data
    }
    
    subscribeToMessages() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                CHANNEL,
                (message) => this.handleMessage(message)
            );
        }
    }
}
```

## Property Decorators

### @api - Public Properties

```javascript
// Passed from parent, can be set by parent
@api recordId;
@api showHeader = false; // With default

// In parent template
<c-membership-card 
    record-id={membershipId}
    show-header
></c-membership-card>
```

### @track - Reactive State

```javascript
// Tracks changes to complex objects/arrays
@track selectedItems = [];
@track membership = {};

// Primitives auto-reactive, but explicit @track is clear
@track isLoading = false;
```

### @wire - Data Binding

```javascript
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = ['Membership__c.Name', 'Membership__c.Status__c'];

@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
wiredMembership({ error, data }) {
    if (data) {
        this.membership = data;
        this.error = undefined;
    } else if (error) {
        this.error = error;
        this.membership = undefined;
    }
}
```

## Communication Patterns

### Parent → Child (via @api)

```javascript
// Parent template
<c-child-component record-id={parentRecordId}></c-child-component>

// Child component
@api recordId;
```

### Child → Parent (via CustomEvent)

```javascript
// Child: Dispatch event
handleSelect() {
    const event = new CustomEvent('select', {
        detail: { selectedId: this.recordId }
    });
    this.dispatchEvent(event);
}

// Parent template: Handle event
<c-child-component onselect={handleSelection}></c-child-component>

// Parent: Handle event
handleSelection(event) {
    this.selectedId = event.detail.selectedId;
}
```

### Sibling Communication (via Lightning Message Service)

```javascript
// Publisher component
import { publish, MessageContext } from 'lightning/messageService';
import CHANNEL from '@salesforce/messageChannel/MembershipChannel__c';

@wire(MessageContext)
messageContext;

publishSelection() {
    const message = { membershipId: this.recordId };
    publish(this.messageContext, CHANNEL, message);
}

// Subscriber component
import { subscribe } from 'lightning/messageService';

subscription;

connectedCallback() {
    this.subscription = subscribe(
        this.messageContext,
        CHANNEL,
        (message) => this.handleMessage(message)
    );
}

handleMessage(message) {
    this.membershipId = message.membershipId;
}
```

## Apex Integration

### Controller Pattern

**See:** `apex-development` skill for controller standards

```javascript
// component.js
import getMembership from '@salesforce/apex/MembershipController.getMembership';
import renewMembership from '@salesforce/apex/MembershipController.renewMembership';

export default class MembershipCard extends LightningElement {
    @api recordId;
    membership;
    error;
    
    connectedCallback() {
        this.loadMembership();
    }
    
    loadMembership() {
        getMembership({ membershipId: this.recordId })
            .then(result => {
                this.membership = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.showError(error);
            });
    }
    
    handleRenew() {
        renewMembership({ membershipId: this.recordId })
            .then(() => {
                this.showSuccess('Membership renewed');
                this.loadMembership(); // Refresh
            })
            .catch(error => {
                this.showError(error);
            });
    }
}
```

### Error Handling

```javascript
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

showError(error) {
    const message = error.body?.message || error.message || 'Unknown error';
    this.dispatchEvent(new ShowToastEvent({
        title: 'Error',
        message: message,
        variant: 'error'
    }));
}

showSuccess(message) {
    this.dispatchEvent(new ShowToastEvent({
        title: 'Success',
        message: message,
        variant: 'success'
    }));
}
```

## Lightning Data Service

### Using LDS with Wire

```javascript
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

// Read
@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
wiredRecord;

// Update
handleUpdate() {
    const fields = {
        Id spec: this.recordId,
        Status__c: 'Active'
    };
    
    updateRecord({ fields })
        .then(() => {
            this.showSuccess('Updated');
        })
        .catch(error => {
            this.showError(error);
        });
}
```

## SLDS Design System

```html
<template>
    <!-- Cards -->
    <lightning-card title="Membership Details" icon-name="standard:account">
        <div class="slds-p-horizontal_medium">
            <!-- Content -->
        </div>
    </lightning-card>
    
    <!-- Layout -->
    <div class="slds-grid slds-wrap slds-gutters">
        <div class="slds-col slds-size_1-of-2">
            <!-- Column 1 -->
        </div>
        <div class="slds-col slds-size_1-of-2">
            <!-- Column 2 -->
        </div>
    </div>
    
    <!-- Spacing -->
    <div class="slds-m-top_medium slds-p-around_small">
        <!-- Content -->
    </div>
    
    <!-- Buttons -->
    <lightning-button 
        label="Renew"
        variant="brand"
        onclick={handleRenew}
        disabled={isDisabled}
    ></lightning-button>
</template>
```

## Frontend Aesthetics

> [!NOTE]
> **See:** `frontend-design` skill for premium UI/UX patterns

### Custom Styling

```css
/* membershipCard.css */
:host {
    --card-background: #ffffff;
    --primary-color: #0070d2;
}

.membership-card {
    background: var(--card-background);
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    transition: transform 0.2s;
}

.membership-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
}

.status-active {
    color: #04844b;
    font-weight: 600;
}
```

### Typography

```css
.heading {
    font-family: 'Salesforce Sans', Arial, sans-serif;
    font-size: 1.5rem;
    font-weight: 700;
    line-height: 1.25;
}

.body-text {
    font-size: 0.875rem;
    line-height: 1.5;
    color: #3e3e3c;
}
```

## Element Multi-Community Support

```javascript
import USER_ID from '@salesforce/user/Id';
import { getCommunityData } from 'c/multiCommunityUtil';

connectedCallback() {
    // Get community-specific context
    this.currentSiteDetail = getCommunityData(USER_ID);
    this.accountId = this.currentSiteDetail?.contextRecordId;
}
```

## Accessibility

```html
<template>
    <!-- ARIA labels -->
    <lightning-button
        label="Submit"
        onclick={handleSubmit}
        aria-disabled={isDisabled}
        aria-label="Submit membership form"
    ></lightning-button>
    
    <!-- Live regions -->
    <div role="alert" aria-live="polite" aria-atomic="true">
        {statusMessage}
    </div>
    
    <!-- Keyboard navigation -->
    <div 
        tabindex="0"
        role="button"
        onkeydown={handleKeyDown}
        class="interactive-element"
    >
        Click or press Enter
    </div>
</template>
```

```javascript
handleKeyDown(event) {
    if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        this.handleAction();
    }
}
```

## Testing with Jest

```javascript
// __tests__/membershipCard.test.js
import { createElement } from 'lwc';
import MembershipCard from 'c/membershipCard';

describe('c-membership-card', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });
    
    it('renders with record id', () => {
        const element = createElement('c-membership-card', {
            is: MembershipCard
        });
        element.recordId = '001000000000001';
        document.body.appendChild(element);
        
        expect(element.recordId).toBe('001000000000001');
    });
    
    it('handles button click', () => {
        const element = createElement('c-membership-card', {
            is: MembershipCard
        });
        document.body.appendChild(element);
        
        const button = element.shadowRoot.querySelector('lightning-button');
        button.click();
        
        // Assertions
    });
});
```

## Do's and Don'ts

### ✅ DO

- Use Lightning Base Components
- Implement SLDS design patterns
- Make components accessible (ARIA, keyboard nav)
- Use LMS for sibling communication
- Handle loading and error states
- Use CSS custom properties for theming
- Test with Jest
- Reference frontend-design for premium UI

### ❌ DON'T

- Use jQuery or other libraries
- Manipulate DOM directly outside component
- Use `document.querySelector` globally
- Hardcode styles (use CSS custom properties)
- Skip accessibility attributes
- Ignore error handling

## Element-Specific Conventions

1. **Location**: `force-app/ui/lwc/<componentName>/`
2. **Naming**: camelCase
3. **Controllers**: Dedicated Apex in `force-app/ui/controller/`
4. **Utilities**: Reusable in `c/constantUtils`, `c/communityUtil`
5. **Testing**: Jest tests in `__tests__/`

### Variable Naming Rules

**No underscore prefix on any variable.** All names — including private backing fields for `@api` getters — must be camelCase.

```javascript
// ✅ DO — backing fields use descriptive camelCase suffix
valueInternal     = 0;
sizeInternal      = 'medium';
isLoadingInternal = false;
credentialDataInternal;
completedGroupsNum = 0;
totalGroupsNum     = 0;
fieldCount         = 0;

@api
get value() { return this.valueInternal; }
set value(val) { this.valueInternal = ...; }

// ❌ DON'T — underscore prefix is forbidden
_value     = 0;
_size      = 'medium';
_isLoading = false;
```

Recommended suffix patterns for private backing fields:
- `Internal` — for `@api` getter/setter backing (e.g. `valueInternal`, `sizeInternal`)
- `Num` — for numeric counters that shadow a getter name (e.g. `completedGroupsNum`)
- No suffix needed when there is no naming conflict (e.g. `fieldCount`, `isLoading` when no `@api` getter of the same name)

### data-id Rules

Every interactive or meaningful HTML element **must** have a `data-id` attribute. Values must be:
- **Unique** within the component template
- **kebab-case** (all lowercase, words separated by hyphens)

```html
<!-- ✅ DO — unique, kebab-case data-id on every element -->
<lightning-button data-id="renew-button" label="Renew" onclick={handleRenew}></lightning-button>
<lightning-button data-id="cancel-button" label="Cancel" onclick={handleCancel}></lightning-button>
<div data-id="credential-card" class="card"></div>
<lightning-input data-id="start-date-input" label="Start Date"></lightning-input>

<!-- ❌ DON'T — missing data-id -->
<lightning-button label="Renew" onclick={handleRenew}></lightning-button>

<!-- ❌ DON'T — camelCase or PascalCase -->
<lightning-button data-id="renewButton" label="Renew"></lightning-button>
<lightning-button data-id="RenewButton" label="Renew"></lightning-button>

<!-- ❌ DON'T — duplicate data-id within the same template -->
<lightning-button data-id="action-button" label="Renew"></lightning-button>
<lightning-button data-id="action-button" label="Cancel"></lightning-button>
```

In JavaScript, reference elements by `data-id` using `dataset`:

```javascript
handleClick(event) {
    const id = event.target.dataset.id; // reads data-id value
}
```

## Interactions with Other Skills

### Uses
- **frontend-design** - UI/UX aesthetics and design patterns
- **apex-development** - Apex controller integration
- **experience-cloud-configuration** - Community-specific patterns

### References
- **salesforce-architecture** - Component architecture
- **packaging-isvforce** - Namespace considerations

## Quick Reference

| Task | Pattern |
|------|---------|
| Public property | `@api propertyName` |
| Reactive state | `@track stateObject` |
| Wire Apex | `@wire(methodName, { param: '$property' })` |
| Parent→Child | `@api` properties |
| Child→Parent | `CustomEvent` + dispatch |
| Sibling comm | Lightning Message Service |
| Error handling | Toast events |
| Styling | SLDS + custom CSS |
| Accessibility | ARIA labels, keyboard nav |
| Premium UI | See `frontend-design` skill |
