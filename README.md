# AI-Powered GTM Activation Engine

## Objective
Reduce funnel leakage and improve product-led conversion using automation and AI.

## Funnel Problems
1. Lead → Signup conversion is low.
2. Product Run → Team Invite conversion is low.

## Solution
A Make-based workflow receives behavioral events, detects where the user is stuck in the funnel, and generates personalized recovery actions using OpenAI.

## PoC Scope
This PoC uses webhook-based sample payloads to simulate production data from HubSpot, PostHog, ZoomInfo, Salesforce, and Snowflake.

## Workflow Logic
Path A:
If completed_setup = false → generate setup activation email.

Path B:
If successful_product_run = true and team_members_added = 0 → generate team adoption email and simulated Salesforce task.

## Production Architecture
Elementor → HubSpot → ZoomInfo → PostHog → Snowflake → Make → OpenAI → HubSpot/Gmail/Salesforce

## Tools Used
- Make
- OpenAI
- Webhooks
- HTML webhook responses
