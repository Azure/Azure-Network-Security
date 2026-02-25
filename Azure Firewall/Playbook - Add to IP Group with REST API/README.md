## Azure Firewall IP Group Auto‑Block Playbook (REST API)

## Overview

This Microsoft Sentinel playbook automates **malicious IP containment** by dynamically updating an **Azure Firewall IP Group** when an incident is created.  
Instead of modifying firewall rules directly, the playbook updates a referenced **IP Group**, ensuring **safe, scalable, and atomic enforcement** across all firewall rules that consume the group.

The playbook:

*   Extracts IP entities from Sentinel incidents
*   De‑duplicates against existing IP Group entries
*   Performs **a single consolidated PUT update** to the IP Group
*   Adds an audit comment back to the Sentinel incident
*   Uses **Managed Identity** and **Azure Resource Manager REST APIs** (no custom connector)

***

## What This Playbook Does

### High‑level flow

1.  **Trigger** – Runs when a Microsoft Sentinel incident is created
2.  **Extract IPs** – Pulls IP entities from the incident
3.  **Fetch IP Group** – Reads the existing Azure Firewall IP Group
4.  **Compare & Aggregate**
    *   Skips IPs already present
    *   Collects only new IPs
5.  **Single Update**
    *   Updates the IP Group **once** with the merged IP list
6.  **Audit**
    *   Adds a comment to the Sentinel incident indicating:
        *   IPs added, or
        *   No change required

### Why IP Groups?

*   One update applies to **all firewall rules** referencing the group
*   Eliminates rule sprawl
*   Reduces API throttling and race conditions
*   Supports multi‑firewall and hub‑and‑spoke deployments

***

## Key Design Characteristics

*   ✅ **Single PUT operation** (no per‑IP updates)
*   ✅ **Idempotent** (safe to run multiple times)
*   ✅ **No custom connectors**
*   ✅ **Managed Identity authentication**
*   ✅ **Fully ARM‑deployable**
*   ✅ **Sanitized resource naming** (no invalid characters)

***

## Prerequisites

### Azure & Sentinel

*   Microsoft Sentinel enabled on a Log Analytics workspace
*   Sentinel incidents must contain **IP entities**

### Azure Firewall

*   Azure Firewall deployed
*   An existing **IP Group**
*   Firewall rules referencing the IP Group

### Permissions (Critical)

Assign these roles **after deployment**:

#### Logic App Managed Identity

| Scope                     | Role                                              |
| ------------------------- | ------------------------------------------------- |
| IP Group resource (or RG) | **Contributor**                                   |
| Sentinel workspace        | **Microsoft Sentinel Responder** (or Contributor) |

> No API connection authorization is required for Sentinel when using Managed Identity.

***

## Deployment Instructions

### Supported Deployment Method (Required)

> ⚠️ **Deploy via Microsoft Sentinel**, not generic ARM deployment.

1.  Go to **Microsoft Sentinel**
2.  Select your workspace
3.  Navigate to **Automation → Playbooks**
4.  Click **Create → Playbook with incident trigger**
5.  Choose **Deploy from custom template**
6.  Paste the ARM template
7.  Provide the required parameters:
    *   `logicAppName`
    *   `ipGroupName`
    *   `ipGroupResourceGroup`
    *   `ipGroupSubscriptionId`
8.  Deploy

Sentinel will automatically:

*   Create the Sentinel API connection
*   Wire `$connections` correctly
*   Enable the incident trigger

***

## Post‑Deployment Configuration

1.  Open the deployed Logic App
2.  Go to **Identity**
3.  Ensure **System Assigned Managed Identity** is enabled
4.  Assign RBAC roles (see Prerequisites)
5.  In Sentinel:
    *   Create or update an **Automation Rule**
    *   Trigger on *Incident created*
    *   Attach this playbook

***

## Checks & Balances (Safety Controls)

### Built‑in Safeguards

*   **De‑duplication**: IPs already in the group are skipped
*   **Atomic update**: Single PUT prevents race conditions
*   **Sequential processing**: IP loop runs with concurrency = 1
*   **Audit trail**: Every run leaves an incident comment

### Operational Checks

*   Verify IP Group size limits are not exceeded
*   Monitor Logic App run history for failed PUT operations
*   Confirm firewall rules reference the correct IP Group
*   Validate that only trusted analytics rules trigger this playbook

***

## Limitations & Considerations

*   Designed for **IPv4** IP entities
*   Assumes Sentinel incidents contain structured IP entities
*   Does not validate IP reputation (pure response playbook)
*   Firewall enforcement depends on rule priority and policy design

***

## When to Use This Playbook

✅ Automated containment for known‑bad IPs  
✅ SOC‑driven response via automation rules  
✅ Environments with multiple firewalls  
✅ Customers avoiding custom connectors


***

## Summary

This playbook provides a **clean, scalable, and production‑safe** approach to automated IP blocking with Microsoft Sentinel and Azure Firewall.  
By using **IP Groups + REST APIs + Managed Identity**, it avoids common pitfalls such as rule sprawl, API throttling, and brittle custom connectors—making it ideal for enterprise SOC operations.
