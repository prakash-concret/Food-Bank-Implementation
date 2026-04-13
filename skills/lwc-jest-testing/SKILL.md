---
name: lwc-jest-testing
description: Jest testing patterns for Lightning Web Components in Element AMS. Use when writing, fixing, or reviewing LWC Jest tests. Covers file structure, createComponent helper, flushPromises, DOM querying by data-id, form-factor-aware selectors, virtual module mocking, and event testing.
---

# LWC Jest Testing

## Purpose

Define Element's **standard Jest testing patterns** for Lightning Web Components, ensuring tests accurately reflect the rendered template and follow consistent conventions.

## When to Use

- Writing new Jest tests for an LWC component
- Fixing failing Jest tests
- Reviewing test coverage for an LWC component

---

## File Structure

- One test file per component: `force-app/ui/lwc/<componentName>/__tests__/<componentName>.test.js`
- When a component has distinct desktop/mobile layouts driven by `FORM_FACTOR`, create **two** test files:
  - `<componentName>LargeDevice.test.js` — mock `FORM_FACTOR` as `"Large"`
  - `<componentName>SmallDevice.test.js` — mock `FORM_FACTOR` as `"Small"`

---

## Standard Test Pattern

```javascript
// __tests__/credentialDetailInfo.test.js
import { createElement } from "lwc";
import CredentialDetailInfo from "c/credentialDetailInfo";

// ── Virtual module mocks ──────────────────────────────────────────────────────
// Always pass { virtual: true } for @salesforce/* imports.
// Declare ALL mocks before describe().
jest.mock("@salesforce/client/formFactor", () => {
    return { default: "Large" };
}, { virtual: true });

jest.mock(
    "@salesforce/schema/Credential__c",
    () => { return { default: { objectApiName: "Credential__c" } }; },
    { virtual: true }
);

jest.mock(
    "@salesforce/schema/Credential__c.Status__c",
    () => { return { default: { fieldApiName: "Status__c" } }; },
    { virtual: true }
);

describe("c-credential-detail-info", () => {

    // ── Teardown ──────────────────────────────────────────────────────────────
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    // ── flushPromises ─────────────────────────────────────────────────────────
    // Defined inside describe. Resolves the microtask queue so the DOM updates
    // after @api setters / connectedCallback / wire results.
    async function flushPromises() {
        return Promise.resolve();
    }

    // ── Shared mock data ──────────────────────────────────────────────────────
    // Defined at describe scope so all tests can reference or spread-override it.
    const mockCredentialData = {
        namespacePrefix: "",
        credentialObj: {
            Id: "001xx000003DHP0AAO",
            Credential_Program__r: { Name: "Program A" },
            Credential_Level__r: { Name: "Level 1" }
        },
        credentialStatus: "Active",
        credentialActions: [
            { label: "Renew", actionType: "Flow", actionTarget: "Renew_Flow", sortOrder: 1 }
        ],
        fieldSetFields: ["Name"],
        fieldMetadataMap: {
            Name: { label: "Name", dataType: "TEXT" }
        }
    };

    // ── createComponent helper ────────────────────────────────────────────────
    // Always set @api properties BEFORE document.body.appendChild so the
    // setter fires with the component already connected.
    // Accept a data param with a default so tests can pass spread-overrides.
    function createComponent(data = mockCredentialData) {
        const element = createElement("c-credential-detail-info", {
            is: CredentialDetailInfo
        });
        element.credentialData = data;
        document.body.appendChild(element);
        return element;
    }

    // ── Tests ─────────────────────────────────────────────────────────────────

    it("renders credential name correctly", async () => {
        const element = createComponent();
        await flushPromises();

        const nameEl = element.shadowRoot.querySelector('[data-id="credential-name"]');
        expect(nameEl.textContent).toBe("Program A - Level 1");
    });

    it("renders status badge when status exists", async () => {
        const element = createComponent();
        await flushPromises();

        // Desktop branch (FORM_FACTOR=Large) renders credential-status-badge-circle.
        // Mobile branch (FORM_FACTOR=Small) renders credential-status-badge.
        // Use the data-id that matches the mocked form factor.
        const badge = element.shadowRoot.querySelector('[data-id="credential-status-badge-circle"]');
        expect(badge).not.toBeNull();
    });

    it("does not render status badge if status is missing", async () => {
        const data = { ...mockCredentialData, credentialStatus: null };
        const element = createComponent(data);
        await flushPromises();

        const badge = element.shadowRoot.querySelector('[data-id="credential-status-badge-circle"]');
        expect(badge).toBeNull();
    });

    it("renders field items when fieldSetFields are present", async () => {
        const element = createComponent();
        await flushPromises();

        // Use querySelectorAll for elements rendered via for:each.
        const fieldItems = element.shadowRoot.querySelectorAll('[data-id="credential-field-item"]');
        expect(fieldItems.length).toBeGreaterThan(0);
    });

    it("renders action button group when actions exist", async () => {
        const element = createComponent();
        await flushPromises();

        const actionButtonGroup = element.shadowRoot.querySelector("c-action-button-group");
        expect(actionButtonGroup).not.toBeNull();
    });

    it("does not render action button group when no actions exist", async () => {
        const data = { ...mockCredentialData, credentialActions: [] };
        const element = createComponent(data);
        await flushPromises();

        const actionButtonGroup = element.shadowRoot.querySelector("c-action-button-group");
        expect(actionButtonGroup).toBeNull();
    });

    it("passes actions to action button group", async () => {
        const element = createComponent();
        await flushPromises();

        const actionButtonGroup = element.shadowRoot.querySelector("c-action-button-group");
        expect(actionButtonGroup.actions).toEqual(mockCredentialData.credentialActions);
    });

    it("re-dispatches actionclick event with credentialId appended", async () => {
        const element = createComponent();
        const handler = jest.fn();
        element.addEventListener("actionclick", handler);
        await flushPromises();

        // Simulate the child event — dispatch from the child element in shadowRoot
        const actionButtonGroup = element.shadowRoot.querySelector("c-action-button-group");
        actionButtonGroup.dispatchEvent(
            new CustomEvent("actionclick", {
                detail: { flowApiName: "Renew_Flow", isFlow: true, modalHeader: "Renew" }
            })
        );

        expect(handler).toHaveBeenCalled();
        const eventDetail = handler.mock.calls[0][0].detail;
        expect(eventDetail.flowApiName).toBe("Renew_Flow");
        expect(eventDetail.isFlow).toBe(true);
        expect(eventDetail.credentialId).toBe("001xx000003DHP0AAO");
    });
});
```

---

## Key Rules

### 1. Virtual module mocks — declare before `describe`

Always pass `{ virtual: true }` for Salesforce platform imports. Mock **all** imports used by the component under test:

```javascript
jest.mock("@salesforce/client/formFactor", () => ({ default: "Large" }), { virtual: true });
jest.mock("@salesforce/schema/MyObject__c", () => ({ default: { objectApiName: "MyObject__c" } }), { virtual: true });
jest.mock("@salesforce/label/c.MyLabel", () => ({ default: "My Label" }), { virtual: true });
```

### 2. `createComponent` helper — set `@api` props before `appendChild`

```javascript
function createComponent(data = mockData) {
    const element = createElement("c-my-component", { is: MyComponent });
    element.myApiProp = data;   // ← set BEFORE appendChild
    document.body.appendChild(element);
    return element;
}
```

Setting props after `appendChild` can miss setter execution depending on LWC lifecycle timing.

### 3. `flushPromises` — always `await` before DOM queries

```javascript
async function flushPromises() {
    return Promise.resolve();
}

it("...", async () => {
    const element = createComponent();
    await flushPromises();   // ← wait before querying DOM
    // ...
});
```

### 4. Query by `data-id` — verify against the actual HTML file

Always query with `[data-id="..."]` matching the exact attribute in the template. **Before writing a test, read the HTML file** to confirm the `data-id` exists.

| Query type | When to use |
|---|---|
| `querySelector('[data-id="..."]')` | Single element |
| `querySelectorAll('[data-id="..."]')` | Repeated elements via `for:each` |
| `querySelector('c-child-component')` | Child component element |

### 5. Form-factor-aware selectors

When a component has both mobile and desktop branches, `data-id` values can differ:

```javascript
// Desktop branch renders:  data-id="credential-status-badge-circle"
// Mobile  branch renders:  data-id="credential-status-badge"

// In LargeDevice test (FORM_FACTOR="Large"):
const badge = element.shadowRoot.querySelector('[data-id="credential-status-badge-circle"]');

// In SmallDevice test (FORM_FACTOR="Small"):
const badge = element.shadowRoot.querySelector('[data-id="credential-status-badge"]');
```

If a test uses the wrong `data-id` it can **pass for the wrong reason** (querying a selector that doesn't exist returns `null`, and a "should be null" assertion passes even when the element is rendered in the other branch under a different `data-id`).

### 6. Event testing — attach listener before `flushPromises`

```javascript
it("re-dispatches event", async () => {
    const element = createComponent();
    const handler = jest.fn();
    element.addEventListener("myevent", handler);   // ← before flushPromises
    await flushPromises();

    // Dispatch from the child inside shadowRoot
    const child = element.shadowRoot.querySelector("c-child");
    child.dispatchEvent(new CustomEvent("myevent", { detail: { foo: "bar" } }));

    expect(handler).toHaveBeenCalled();
    const detail = handler.mock.calls[0][0].detail;
    expect(detail.foo).toBe("bar");
});
```

### 7. `afterEach` cleanup

Always drain `document.body` and clear mocks:

```javascript
afterEach(() => {
    while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
});
```

### 8. Spread-override pattern for negative tests

```javascript
it("does not render X when Y is absent", async () => {
    const data = { ...mockData, someField: null };   // spread + override
    const element = createComponent(data);
    await flushPromises();

    const el = element.shadowRoot.querySelector('[data-id="some-element"]');
    expect(el).toBeNull();
});
```

---

## Common Pitfalls

| Pitfall | Fix |
|---|---|
| Wrong `data-id` for the active form-factor branch | Read the HTML file; mock the correct `FORM_FACTOR` |
| `querySelectorAll` returns empty for `for:each` elements | Ensure data has items; verify the exact `data-id` |
| Test passes for wrong reason (null selector on wrong branch) | Use correct `data-id` per mocked form factor |
| `@api` setter never fires | Set props **before** `appendChild`, not after |
| Stale DOM across tests | Always drain `document.body` in `afterEach` |

---

## Interactions with Other Skills

- **lwc-development** — component structure, `data-id` rules, variable naming
- **apex-testing** — Apex-side testing strategy (separate skill)
