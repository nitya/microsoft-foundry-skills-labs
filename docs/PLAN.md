# Workshop Plan: Build & Optimize AI Agents On Microsoft Foundry With Azure Skills

> **Duration:** 60 minutes &nbsp;|&nbsp; **Format:** Hands-on, instructor-led &nbsp;|&nbsp; **Level:** Intermediate
>
> **Scenario:** You are a developer at **Zava Outdoors**, a retail company selling outdoor gear. Your team needs to build an AI-powered customer support chatbot. You will build, deploy, evaluate, and optimize this agent entirely through natural language using **Azure Skills** with **GitHub Copilot**.
>
> **Step-by-step instructions:** [docs/README.md](README.md)

---

## Learning Objectives

| # | Objective | Module |
|---|-----------|--------|
| 1 | Install and configure Azure Skills in GitHub Copilot CLI | Module 1 |
| 2 | Use the `microsoft-foundry` skill to create an AI agent with custom product data | Module 2 |
| 3 | Deploy the agent as a hosted agent on Microsoft Foundry | Module 3 |
| 4 | Run batch evaluations and analyze agent quality using Foundry evaluators | Module 4 |
| 5 | Optimize agent prompts and redeploy an improved version | Module 5 |

---

## Workshop Flow

All agent code and data are created inside a **`zava-outdoors/`** project folder.

```
    +----------+    +----------+    +-----------+
    |  BUILD   |--->|  DEPLOY  |--->| EVALUATE  |
    +----------+    +----------+    +-----+-----+
         ^                                |
         |          +-----------+         |
         +----------| OPTIMIZE  |<--------+
                    +-----------+

    Module:  M2         M3          M4          M5
```

| Module | Title | Time | Key Activity |
|--------|-------|------|--------------|
| **M0** | Environment & Azure Setup | 5 min | Fork repo, Codespaces, provision Foundry project + model + App Insights, run `scripts/setup-env.sh` then `scripts/create-acr.sh` |
| **M1** | Install Azure Skills | 10 min | Plugin install, verify `microsoft-foundry` skill |
| **M2** | Build the Agent | 15 min | Scaffold `zava-outdoors/`, product data, system prompt, wire data, local test |
| **M3** | Deploy to Foundry | 10 min | ACR build, hosted agent deploy, invoke to verify |
| **M4** | Evaluate & Observe | 10 min | Eval dataset, baseline evaluation, analyze results |
| **M5** | Optimize & Redeploy | 10 min | Prompt optimizer, redeploy v2, compare scores |

---

## Pre-Requisites

### Accounts & Subscriptions

- [ ] GitHub account with Codespaces quota
- [ ] GitHub Copilot Pro subscription (Claude model access recommended)
- [ ] Azure subscription (resources created during Module 0):
  - Azure AI Foundry project with a deployed chat model (e.g., `gpt-4.1` or `gpt-4o-mini`)
  - Application Insights connected to the project
  - Azure Container Registry (ACR) in the same resource group
  - Foundry managed identity with `Container Registry Repository Reader` on the ACR

### Environment Configuration

The repo provides `scripts/sample.env` (template), `scripts/setup-env.sh` (auto-discovery), and `scripts/create-acr.sh` (ACR + RBAC).
Run `scripts/setup-env.sh` after creating your Foundry project, then `scripts/create-acr.sh` to create the ACR and assign roles.
See [docs/README.md → Module 0](README.md#module-0--project-setup) for full details.

---

## Zava Outdoors Product Catalog

The agent uses an 11-product outdoor gear catalog adapted from [Contoso Outdoors](https://github.com/Azure-Samples/contoso-web/tree/main/public):

| ID | Product | Price | Category | Brand |
|----|---------|-------|----------|-------|
| 1 | TrailMaster X4 Tent | $250 | Tents | OutdoorLiving |
| 8 | Alpine Explorer Tent | $350 | Tents | AlpineGear |
| 15 | SkyView 2-Person Tent | $200 | Tents | OutdoorLiving |
| 2 | Adventurer Pro Backpack | $90 | Backpacks | HikeMate |
| 9 | SummitClimber Backpack | $120 | Backpacks | HikeMate |
| 3 | Summit Breeze Jacket | $120 | Hiking Clothing | MountainStyle |
| 10 | TrailBlaze Hiking Pants | $75 | Hiking Clothing | MountainStyle |
| 4 | TrekReady Hiking Boots | $140 | Hiking Footwear | TrekReady |
| 5 | BaseCamp Folding Table | $60 | Camping Tables | CampBuddy |
| 6 | EcoFire Camping Stove | $80 | Camping Stoves | EcoFire |
| 7 | CozyNights Sleeping Bag | $100 | Sleeping Bags | CozyNights |

Each product includes `care_instructions` and `safety_notes` fields to support care/safety evaluation scenarios.

---

## Workspace Structure After Completion

```
microsoft-foundry-skills-labs/
+-- zava-outdoors/                        <-- all agent code lives here
|   +-- main.py                           Agent entry point
|   +-- agent.yaml                        Deployment contract
|   +-- Dockerfile                        Container image
|   +-- requirements.txt                  Python deps
|   +-- data/
|   |   +-- products.json                 Product catalog (11 products)
|   +-- .foundry/
|       +-- agent-metadata.yaml           Agent metadata
|       +-- OPTIMIZATION_LOG.md           Prompt change history
|       +-- datasets/
|       |   +-- eval_baseline.jsonl       Evaluation test cases
|       +-- results/                      Evaluation results (per run)
|       +-- evaluators/
|           +-- optimized_instructions.md Optimized system prompt
+-- scripts/
|   +-- sample.env                        Environment template
|   +-- setup-env.sh                      Auto-discover Azure resources → .env
|   +-- create-acr.sh                     Create ACR + assign RBAC roles
+-- docs/
    +-- PLAN.md                           This plan (high-level)
    +-- README.md                         Step-by-step workshop instructions
```

---

## Resources

| Resource | Link |
|----------|------|
| Azure Skills Overview | https://learn.microsoft.com/en-us/azure/developer/azure-skills/overview |
| Azure Skills Install & Configure | https://learn.microsoft.com/en-us/azure/developer/azure-skills/install |
| Azure Skills Quickstart | https://learn.microsoft.com/en-us/azure/developer/azure-skills/quickstart |
| Microsoft Foundry Skill Reference | https://learn.microsoft.com/en-us/azure/developer/azure-skills/skills/microsoft-foundry |
| Foundry Observability Skills Lab | https://github.com/microsoft/foundry-observability-skills |
| Contoso Web (Data Source) | https://github.com/Azure-Samples/contoso-web/tree/main/public |
