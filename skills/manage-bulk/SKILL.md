---
name: lark-manage-bulk
description: This skill should be used when the user wants to create a bunch of workflows in lark in bulk. This is common when the user is either onboarding to lark and currently they have zero or very few tests setup, or if they are trying to increase coverage for their product surface area and want to add a bunch of new tests. Handles the full flow from understanding the product area, generating test cases, writing the import JSON file, validating, and uploading via the CLI jobs functionality.
license: MIT
compatibility: "Requires the getlark CLI (`npm install -g @getlark/cli`) and `LARKCI_API_KEY` in the environment. Run `/getlark:setup` first if either is missing."
allowed-tools: Bash, AskUserQuestion, Write, Read, StrReplace
argument-hint: "[product area description]"
---

# manage-bulk

Bulk-import workflows into getlark by collaborating with the user to understand their product area, generating comprehensive test cases, and uploading them via the CLI `jobs` functionality. This skill is ideal for onboarding (going from zero to full coverage) or expanding test coverage for a specific product surface.

getlark workflows can test any surface — web UIs, HTTP/GraphQL APIs, CLIs, shell scripts, data pipelines, or mixed flows. Do not assume the target is a browser URL unless the user says so.

## Procedure

### Step 1 — Understand the product area

Ask the user to describe the product area they want to create test workflows for. Gather:

- **What is the product/feature?** (e.g., "our checkout flow", "the user management API", "the CLI tool for data imports")
- **What is the target?** (URL, API base, CLI binary, script path, etc.)
- **Are there specific user journeys or critical paths to cover?**
- **Are there credentials or secret contexts needed?** If yes, confirm they exist via `getlark secret-contexts list`.
- **Should workflows be grouped?** If yes, identify or create a workflow group via `getlark workflow-groups list`.

If the user invoked the skill with a description already, use that as the starting point and ask only clarifying questions for gaps.

### Step 2 — Assess existing coverage

Before generating new test cases, fetch all existing workflows to understand what coverage already exists:

```bash
getlark workflows list --limit 100
```

If there are more than 100 workflows, paginate with `--offset` until all are fetched. Summarize the existing coverage for the user:

- Group workflows by feature area or theme (infer from names/descriptions)
- Highlight which areas of the product already have tests
- Identify gaps — areas the user mentioned in Step 1 that have no existing workflows

This prevents duplicate coverage and helps focus the new test cases on genuine gaps. If the user's target product area is already well-covered, let them know and ask whether they want to supplement with edge cases or shift focus to a different area.

### Step 3 — Research and generate test cases

Based on the product area and the coverage gaps identified in Step 2, develop a comprehensive set of test cases. Think about:

- **Happy paths** — core user journeys that must always work (login, checkout, CRUD operations, etc.)
- **Edge cases** — boundary conditions, empty states, max-length inputs, concurrent actions
- **Error handling** — invalid inputs, unauthorized access, network failures, graceful degradation
- **Cross-feature interactions** — flows that span multiple features or services
- **Regression-prone areas** — features that break often or have complex dependencies

For each test case, write a clear, actionable description that includes the target and ordered steps. The description is what the AI agent reads at runtime to perform the test — be specific enough that someone unfamiliar with the product could follow the steps.

**Choosing mode**: Prefer `deterministic` when possible — deterministic tests are cheaper and faster to run. Use `ai_driven` only when the test requires adaptive behavior (e.g., dynamic content, unpredictable UI states, flows that change frequently). A good default split is mostly deterministic with a handful of ai_driven tests for flows where flexibility is genuinely needed.

### Step 4 — Write the import JSON file

Create a JSON file (default: `workflows-import.json` in the current working directory) that follows the `workflow_import` schema:

```json
{
  "workflows": [
    {
      "name": "Descriptive Test Name",
      "description": "Go to <target>, perform <action 1>, then <action 2>, assert <expected outcome>.",
      "mode": "ai_driven",
      "secret_contexts": ["context-name"],
      "group_id": "wgrp_..."
    }
  ]
}
```

Schema rules:
- `name` (string, required) — concise, Title-Case name (3–8 words) capturing the test intent.
- `description` (string, required) — full natural-language test steps. Include the target, actions, and assertions. This is what the AI agent uses to execute the test.
- `mode` (required) — `"deterministic"` (locked to generated script, cheaper and faster) or `"ai_driven"` (tolerates minor UI changes, more flexible). Prefer `deterministic` where possible; use `ai_driven` only for flows that genuinely need adaptive behavior.
- `secret_contexts` (array of strings or null, optional) — names of secret contexts the workflow needs for auth/tokens.
- `group_id` (string or null, optional) — workflow group ID to assign the workflow to.

No additional properties are accepted.

### Step 5 — Review and iterate with the user

Present the generated test cases to the user in a readable format (table or numbered list showing name + summary of what each test covers). Ask them to review and suggest changes:

- Are there missing test cases?
- Should any be removed or merged?
- Are descriptions accurate and detailed enough?
- Are the right secret contexts and groups assigned?

Iterate on the JSON file based on feedback. Continue until the user confirms the test cases are ready for import. Do not proceed to validation/upload without explicit user approval.

### Step 6 — Validate and upload

Once the user approves, validate the file first:

```bash
getlark jobs validate --file ./workflows-import.json
```

If validation fails (non-zero exit), read the error output, fix the JSON file accordingly, and re-validate. Common issues:
- Missing required fields (`name`, `description`, `mode`)
- Invalid `mode` value (must be exactly `"ai_driven"` or `"deterministic"`)
- Empty `workflows` array
- Extra properties not in the schema
- Non-unique or empty strings

Once validation passes, upload:

```bash
getlark jobs upload --name "<descriptive job name>" --file ./workflows-import.json
```

Use a descriptive job name that reflects what's being imported (e.g., "Import Checkout Flow Tests" or "Onboarding - User Management API Coverage").

### Step 7 — Report result

The upload command returns the job resource as JSON. Extract and report:

- Job `id`
- Job `status` (typically `pending` or `running` initially)
- **Dashboard URL**: `https://dashboard.getlark.ai/jobs/<id>`

Tell the user the workflow import job was created successfully and share the dashboard URL. Let them know they can:
- Track progress on the dashboard
- Check job status via `getlark jobs get <job_id>`
- Cancel if needed via `getlark jobs cancel <job_id>`

## Guidelines for writing good test descriptions

- Start with the target (URL, API endpoint, CLI command, etc.)
- Use imperative verbs: "Go to", "Click", "Submit", "Assert", "Verify", "Enter", "Wait for"
- End with a clear assertion of expected outcome
- Reference credentials by secret context name, never hardcode secrets in descriptions
- Keep each workflow focused on one logical user journey — don't cram multiple unrelated flows into a single workflow
- Be specific enough that someone unfamiliar with the product can follow the steps

## Example

User says: "I want to add test coverage for our e-commerce checkout flow at https://shop.example.com"

After research and iteration, produce:

```json
{
  "workflows": [
    {
      "name": "Guest Checkout Happy Path",
      "description": "Go to https://shop.example.com/products, add the first available product to cart, proceed to checkout as a guest, fill shipping with valid US address, select standard shipping, enter test card 4242424242424242, submit order, assert order confirmation page shows order number.",
      "mode": "ai_driven",
      "secret_contexts": ["staging"]
    },
    {
      "name": "Empty Cart Checkout Guard",
      "description": "Go to https://shop.example.com/cart with an empty cart, attempt to click Proceed to Checkout, assert the checkout button is disabled or a message says 'Your cart is empty'.",
      "mode": "ai_driven"
    },
    {
      "name": "Apply Discount Code",
      "description": "Go to https://shop.example.com/products, add any product to cart, go to cart, enter discount code SAVE10 in the promo field, click Apply, assert the total decreases and a 'Discount applied' message is shown.",
      "mode": "ai_driven",
      "secret_contexts": ["staging"]
    },
    {
      "name": "Invalid Payment Card Rejected",
      "description": "Go to https://shop.example.com/products, add a product to cart, proceed to checkout as guest, fill valid shipping, enter invalid card number 1234567890123456, submit payment, assert an error message about invalid card is displayed and order is not placed.",
      "mode": "ai_driven",
      "secret_contexts": ["staging"]
    }
  ]
}
```

Then validate and upload:

```bash
getlark jobs validate --file ./workflows-import.json
getlark jobs upload --name "Import Checkout Flow Tests" --file ./workflows-import.json
```

Report the dashboard URL to the user.

## Failure modes

- **Validation errors**: Fix the JSON and re-validate. Do not upload without passing validation.
- **Auth errors on upload**: Verify `LARKCI_API_KEY` is set. Suggest running `/getlark:setup`.
- **Unknown secret context**: Verify via `getlark secret-contexts list` before including in the file.
- **Unknown group ID**: Verify via `getlark workflow-groups list` before including in the file.

## Do NOT

- Do not call `getlark jobs upload` more than once for the same file. Each call creates a separate job — calling it twice will import the workflows twice, resulting in duplicates. If the upload succeeded (returned a job ID and dashboard URL), do not retry it.
- Do not upload without user approval of the test cases.
- Do not skip the validation step — always run `getlark jobs validate` before uploading.
- Do not hardcode secrets or API keys in workflow descriptions. Use secret contexts.
- Do not create excessively vague descriptions. Each must be actionable by an AI agent at runtime.
- Do not invent secret context names or group IDs — verify they exist first.
