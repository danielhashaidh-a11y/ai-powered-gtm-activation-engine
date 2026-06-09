# AI-Powered Funnel Leakage Intelligence Engine

## Overview

The **AI-Powered Funnel Leakage Intelligence Engine** is an automation and AI workflow designed to reduce product-led growth funnel leakage.

The project identifies users who are stuck at key conversion points, analyzes their behavioral and CRM data, and generates personalized GTM recovery actions such as activation emails, Salesforce tasks, and optional Slack-ready messages.

This proof of concept was built in **Make** and is designed to run automatically once per day without requiring an external webhook payload.

---

## Problem Statement

Modern GTM teams often lose potential customers because users get stuck in important funnel stages and no action is taken quickly enough.

The main leakage points addressed by this project are:

1. **Signup completed but setup not completed**
2. **Setup completed but product run not completed**
3. **Product run completed but no team member invited**

These gaps indicate strong user intent but incomplete activation. The goal of this project is to detect these users automatically and trigger intelligent recovery actions.

---

## Solution

The workflow runs daily, queries user and funnel data from Snowflake, identifies users with high leakage risk, and sends relevant records to AI for personalized GTM action generation.

Instead of starting with a webhook, the scenario uses a scheduled trigger so the process can run automatically every day.

### High-Level Flow

```text
Scheduled Trigger
→ Snowflake Query
→ Parse / Normalize Response
→ Iterator
→ Filter Relevant Users
→ AI Decision & Message Generation
→ Salesforce / HubSpot / Slack Actions
```

---

## Key Capabilities

- Runs automatically once per day
- Pulls funnel and behavioral data from Snowflake
- Detects users stuck in important activation stages
- Scores leakage risk using funnel and engagement signals
- Sends only relevant users to AI
- Generates personalized recovery actions
- Supports Salesforce task creation
- Supports HubSpot follow-up mapping
- Supports professional Slack message generation when required
- Designed as a scalable PoC for GTM automation

---

## Use Cases Covered

### 1. Setup Not Completed

Triggered when a user signed up but did not complete onboarding setup.

**Example action:**

- Generate a personalized setup recovery email
- Recommend a follow-up action for the owner

---

### 2. Product Run Not Completed

Triggered when a user completed setup but did not reach the first meaningful product run.

**Example action:**

- Generate a product activation email
- Suggest a customer success follow-up

---

### 3. Team Invite Missing

Triggered when a user completed a successful product run but did not invite a team member.

**Example action:**

- Generate a team adoption email
- Create a Salesforce task for the account owner

---

## Architecture

### Make Scenario

The scenario is built in Make and uses the following structure:

```text
Tools: Basic Trigger
→ Snowflake Query Response
→ Parse JSON
→ Iterator
→ Filters by risk/action logic
→ OpenAI / GPT module
→ Salesforce / HubSpot / Slack output modules
```

### Why a Scheduled Trigger Is Used

A webhook is useful when an external system sends data into Make.

In this project, the workflow should run once per day without waiting for an external payload. Therefore, the correct trigger is a scheduled Make trigger, not a webhook.

```text
Webhook = waits for external data
Scheduled Trigger = starts the flow automatically
```

---

## Example Input Data

The Snowflake query returns records similar to the following:

```json
{
  "email": "sarah@fintechco.com",
  "first_name": "Sarah",
  "last_name": "Levy",
  "company_name": "FinTechCo",
  "industry": "Fintech",
  "company_size": 350,
  "job_title": "VP Operations",
  "salesforce_lead_id": "00Q8d000009ABC",
  "owner_id": "0058d000001XYZ",
  "lead_status": "Open",
  "utm_source": "facebook",
  "utm_medium": "paid_social",
  "utm_campaign": "credit_demo_campaign",
  "landing_page_url": "https://site.com/signup",
  "pages_viewed": 8,
  "visit_count": 4,
  "time_on_site_seconds": 520,
  "pricing_page_viewed": true,
  "demo_page_viewed": true,
  "signup_page_viewed": true,
  "setup_completed_at": "2026-06-02T10:15:00Z",
  "product_run_completed_at": "2026-06-04T14:30:00Z",
  "team_member_added_at": null,
  "stuck_stage": "team_invite_missing",
  "days_stuck": 5,
  "engagement_score": 90,
  "leakage_score": 85,
  "risk_level": "high_risk",
  "suggested_action": "send_team_invite_email_and_create_salesforce_task",
  "send_to_ai": true
}
```

---

## AI Logic

The AI receives the user profile, company context, funnel stage, behavior signals, and suggested action.

It then generates a structured response that can be mapped into downstream GTM systems.

### Example AI Output

```json
{
  "recommended_action": "Create Salesforce task and send team invite email",
  "priority": "High",
  "reason": "The user completed setup and a product run but has not invited any team members, which may block team adoption.",
  "email_subject": "Invite your team to get more value from your workspace",
  "email_body": "Hi Sarah, I noticed your team has already started using the product. A great next step is inviting teammates so everyone can collaborate in one place.",
  "salesforce_task_subject": "Follow up with Sarah about team adoption",
  "salesforce_task_description": "Sarah from FinTechCo completed setup and product run, but no team members were invited. Follow up to encourage team adoption.",
  "slack_required": false,
  "slack_message": null
}
```

---

## Salesforce Mapping

When the AI decides to create a Salesforce task, the following fields can be mapped:

| Salesforce Field | Source |
| --- | --- |
| `WhoId` / `LeadId` | `salesforce_lead_id` |
| `OwnerId` | `owner_id` |
| `Subject` | `salesforce_task_subject` |
| `Description` | `salesforce_task_description` |
| `Priority` | AI priority |
| `Status` | `Not Started` |
| `ActivityDate` | Current date or next business day |
| `Type` | `Follow-up` |

---

## HubSpot Mapping

When creating or updating a HubSpot follow-up action, the following fields can be mapped:

| HubSpot Field | Source |
| --- | --- |
| Contact email | `email` |
| First name | `first_name` |
| Last name | `last_name` |
| Company name | `company_name` |
| Lifecycle / lead status | `lead_status` |
| Funnel stuck stage | `stuck_stage` |
| Risk level | `risk_level` |
| Leakage score | `leakage_score` |
| Suggested action | AI recommended action |
| Last engagement notes | AI reason / summary |

---

## Slack Message Support

If `slack_required` is `true`, the AI generates a professional Slack-ready message.

The Slack message is designed to be:

- Clear
- Modern
- Short
- Actionable
- Easy for GTM teams to understand

Example:

```text
🚨 High-risk funnel leakage detected

Lead: Sarah Levy
Company: FinTechCo
Stage: Team invite missing
Risk: High
Recommended action: Create Salesforce task and send team invite email

Reason:
Sarah completed setup and product run but has not invited teammates yet. This may block team adoption.

Next step:
Account owner should follow up and encourage team invite completion.
```

---

## Why This Project Matters

This project helps GTM teams act faster on high-intent users who are at risk of dropping off.

Instead of manually checking dashboards, the system automatically:

1. Detects leakage
2. Prioritizes users
3. Generates a recommended action
4. Creates operational follow-up tasks
5. Improves activation and conversion opportunities

---

## Tech Stack

- **Make** — Automation and orchestration
- **Snowflake** — Funnel and behavioral data source
- **OpenAI / GPT** — AI decisioning and personalized message generation
- **Salesforce** — Sales task creation
- **HubSpot** — Marketing and CRM follow-up support
- **Slack** — Optional internal GTM alerting

---

## Repository Structure

```text
.
├── README.md
├── make/
│   └── scenario-blueprint.json
├── prompts/
│   ├── setup-recovery-prompt.md
│   ├── product-activation-prompt.md
│   └── team-invite-prompt.md
├── sample-payloads/
│   └── snowflake-response-example.json
└── docs/
    └── architecture.md
```

---

## How to Run

### 1. Import the Make Scenario

Import the Make scenario blueprint into your Make account.

### 2. Configure Connections

Set up the required connections:

- Snowflake
- OpenAI / GPT
- Salesforce
- HubSpot, if used
- Slack, if used

### 3. Configure the Daily Schedule

Set the scenario schedule to run once per day.

Recommended example:

```text
Every day at 08:00
```

### 4. Configure the Snowflake Query

The Snowflake query should return users who are currently stuck in the funnel and include fields such as:

- Contact details
- Company details
- Funnel stage
- Engagement score
- Leakage score
- Suggested action
- `send_to_ai`

### 5. Test the Scenario

Run the scenario manually once and verify:

- Snowflake returns data
- Records are parsed correctly
- Iterator splits records into individual bundles
- Filters route the right users
- AI response is valid JSON
- Salesforce / HubSpot / Slack actions are mapped correctly

---

## Important Implementation Notes

- The scenario should not start with a webhook if the goal is a daily automated process.
- Use a scheduled trigger or Make basic trigger to start the flow.
- If Snowflake returns an array, use an Iterator to process each user separately.
- Use an Array Aggregator only if you need to combine multiple AI outputs into one final result.
- The AI response should be structured JSON so downstream fields can be mapped reliably.
- Filters should prevent low-risk or irrelevant users from being sent to AI.

---

## Project Status

This project is currently a working proof of concept.

The Make workflow demonstrates how AI and automation can be used together to reduce funnel leakage and improve GTM execution.

---

## Author

Built by **Daniel Hashai** as part of a GTM automation and AI assignment.

---

## License

This project is for demonstration and portfolio purposes.
