# Build An AI Agent with Foundry Skills

> **Duration:** 60 minutes &nbsp;|&nbsp; **Format:** Hands-on, instructor-led &nbsp;|&nbsp; **Level:** Intermediate
>
> Build, deploy, evaluate, and optimize a retail AI chatbot for **Zava Outdoors** — an outdoor gear company — using **Azure Skills** and the **`microsoft-foundry`** skill inside GitHub Copilot.

## Outline

| # | Module | What You'll Achieve |
|---|--------|---------------------|
| 0 | [Project Setup](#module-0--project-setup) | Fork repo, launch Codespaces, provision Azure resources, configure environment |
| 1 | [Azure Skills Setup](#module-1--azure-skills-setup) | Install Azure Skills extension and activate the `microsoft-foundry` skill |
| 2 | [Build Agent](#module-2--build-agent) | Scaffold the Zava Outdoors agent with product data, Dockerfile, and agent.yaml |
| 3 | [Deploy Agent](#module-3--deploy-agent) | Containerize and deploy the agent as a hosted agent on Microsoft Foundry |
| 4 | [Evaluate & Observe](#module-4--evaluate--observe) | Run batch evaluations, review traces, and analyze agent quality |
| 5 | [Optimize & Iterate](#module-5--optimize--iterate) | Optimize prompts, redeploy, and compare evaluation results |

---

## Pre-Requisites

- [ ] GitHub account with Codespaces quota
- [ ] GitHub Copilot Pro subscription (Claude model access recommended)
- [ ] Azure subscription — you will create resources in Module 0

---

## Module 0 — Project Setup

### 0.1 Fork & Launch Codespaces

1. Fork this repo to your personal GitHub profile
2. On your fork, click **Code → Codespaces → Create codespace on main**
3. Wait for the devcontainer to build (~2–3 min)

### 0.2 Verify Tools

```bash
python --version   # 3.12.x
node --version     # LTS
az --version       # 2.x
azd version        # latest
```

### 0.3 Provision Azure Resources (Portal)

You need a Foundry project with a deployed model and Application Insights.
Complete Steps A–C in the **Azure/Foundry portal** before returning to Codespaces.

> 💡 **Tip:** Create all resources in the **same resource group and region** (e.g., East US 2)
> to simplify networking and permissions.

---

#### Step A — Create a Foundry Project

1. Visit [https://ai.azure.com](https://ai.azure.com) and sign in with your Azure account
2. Click **Create project** (or go to **Templates** → **Start building** → **Create a new project**)
3. Fill in the project details:
   - **Project name:** `zava-outdoors-project` (or any name you prefer)
   - **Resource group:** select **Create new** → name it `zava-outdoors-rg`
   - **Region:** `East US 2` (recommended for model availability)
4. Click **Create** and wait for provisioning (~2–3 min)
5. Once created, you land on the **Project Overview** page
6. **Copy the Project Endpoint** — you'll need it later
   - Format: `https://<account>.services.ai.azure.com/api/projects/<project>`
   - Find it under: **Overview → Project endpoint**

> 💡 **Note:** The Foundry portal's **Create agent** button on the project landing page
> can automate model deployment and App Insights setup (Steps B & C) in one flow.
> We use manual steps here so you understand each resource and its role.

---

#### Step B — Deploy a Chat Model

The agent needs a deployed LLM to generate responses. This model also serves as
the evaluation judge in Module 4.

1. In the Foundry portal, navigate to your project
2. Go to **Models + endpoints** in the left sidebar
3. Click **+ Deploy model** → **Deploy base model**
4. Search for and select **`gpt-4.1`** (recommended) or `gpt-4o-mini` (fallback)
5. Configure deployment:
   - **Deployment name:** `gpt-4.1` (keep the default)
   - **Tokens per minute (TPM):** set to **≥30K** (needed for batch evaluation)
6. Click **Deploy** and wait for the model to become available
7. **Verify:** the model appears in **Models + endpoints** with status `Succeeded`

> 📝 Note the **Deployment name** — this is your `AZURE_AI_MODEL_DEPLOYMENT_NAME` value.

---

#### Step C — Create a Test Agent & Activate Application Insights

Creating a quick agent in the portal gives you a working playground and lets you
connect Application Insights (required for tracing in Module 4).

1. From the project landing page, click **Create agent**
2. Give it a name: `zava-outdoors-test`
3. Wait for agent creation (~1–2 min)
4. You should see the **Agent Playground** — this confirms your project is agent-ready
5. **Save the agent** when prompted

Now connect Application Insights for observability:

6. Click the **Traces** tab (above the response panel)
7. Click **Connect** to create an Application Insights resource
8. Fill in the details:
   - Accept the default name or enter `zava-outdoors-appinsights`
   - Ensure it creates a new **Log Analytics workspace**
9. Click **Create** and wait for provisioning (~1 min)
10. **Verify:** go to project name drop-down (top left) → **Project Details** → **Connected Resources** tab
    - You should see the Application Insights resource listed

> 📝 The App Insights **Connection String** will be auto-discovered by `setup-env.sh`,
> or you can find it in: Azure Portal → Application Insights → Overview → Connection String.

---

### 0.4 Configure Your Environment (CLI)

The repo includes `scripts/sample.env` (template) and `scripts/setup-env.sh` (auto-discovery script).

**Option A — Automated setup (recommended):**

```bash
chmod +x scripts/setup-env.sh
./scripts/setup-env.sh
```

The script will:
1. Check your Azure CLI login (prompt `az login` if needed)
2. Create `.env` at the repo root from `scripts/sample.env`
3. Auto-discover your Foundry project endpoint, ACR, and App Insights
4. Report any values that still need manual entry

**Option B — Manual setup:**

```bash
cp scripts/sample.env .env
```

Then edit `.env` and fill in the values. Each variable includes a comment explaining where to find it in the Azure/Foundry portal.

### 0.5 Create ACR & Assign Roles (CLI)

Now create the Azure Container Registry and assign RBAC roles. The `create-acr.sh`
script automates the entire process.

```bash
chmod +x scripts/create-acr.sh
./scripts/create-acr.sh
```

The script will:
1. **Create an ACR** (Basic SKU) in your resource group — or reuse an existing one
2. **Discover the Foundry managed identity** from your AI Services account
3. **Assign three RBAC roles** (idempotent — safe to re-run):

| Role | Scope | Purpose |
|------|-------|---------|
| `Container Registry Repository Reader` | ACR | Pull agent container images |
| `Cognitive Services OpenAI User` | AI Services account | Agent calls to deployed model |
| `Monitoring Metrics Publisher` | Resource group | Send telemetry to App Insights |

4. **Log in to ACR** so Docker pushes work from Codespaces
5. **Update `.env`** with the `AZURE_CONTAINER_REGISTRY_NAME` value

> ⚠️ **Note:** The script uses `Container Registry Repository Reader` (not `AcrPull`)
> because hosted agents use ABAC repo-scoped permissions.

#### Summary of Azure Resources

After completing Steps 0.3–0.5, you should have:

| Resource | Name (example) | Purpose |
|----------|----------------|---------|
| **Foundry Project** | `zava-outdoors-project` | Agent hosting, evaluation, traces |
| **Deployed Model** | `gpt-4.1` | Agent LLM + evaluation judge |
| **Application Insights** | `zava-outdoors-appinsights` | Tracing and observability |
| **Container Registry** | `zavaoutdoorsacr` | Docker images for hosted agent |

### 0.6 Load Environment Variables

```bash
set -a && source .env && set +a
az account set --subscription $AZURE_SUBSCRIPTION_ID
az account show   # confirm correct subscription
```

### ✅ Checkpoint

- [ ] Codespace running, VS Code open in browser
- [ ] `.env` file exists with all required values populated
- [ ] `az account show` displays your target subscription
- [ ] `echo $AZURE_AI_PROJECT_ENDPOINT` shows your Foundry project URL

---

## Module 1 — Azure Skills Setup

> **What are Azure Skills?** Agent skills that extend GitHub Copilot with Azure-specific
> workflows — manage resources, deploy apps, and monitor services from your editor.
> 📖 [Overview](https://learn.microsoft.com/en-us/azure/developer/azure-skills/overview)

### 1.1 Install the Plugin

In the **Copilot CLI** terminal:

```
/plugin marketplace add microsoft/azure-skills
/plugin install azure@azure-skills
```

### 1.2 Verify

```
/plugin list
```

You should see `azure@azure-skills` with available skills including `microsoft-foundry`.

### 1.3 Test Connectivity

```
List my Azure subscriptions
```

Copilot queries Azure and shows your subscription(s).

### 1.4 Confirm the Foundry Skill

```
What skills do you have available for Microsoft Foundry?
```

Look for the **microsoft-foundry** skill tag in the response header.

> **💡 Tip:** If the skill doesn't appear, try `Ctrl+Shift+P` → *@azure: Install Azure Skills Globally*, then start a fresh chat session.

### ✅ Checkpoint

- [ ] `/plugin list` shows `azure@azure-skills`
- [ ] Copilot can list your Azure subscriptions
- [ ] `microsoft-foundry` skill is recognized

---

## Module 2 — Build Agent

**Goal:** Create a retail AI chatbot in a `zava-outdoors/` project folder that answers
product questions, recommends gear, and helps customers shop. All data lives under
`zava-outdoors/data/` — the single source of truth for the agent's product knowledge.

### 2.1 Scaffold the Agent

```
Create a hosted agent project in a folder called zava-outdoors/ for "Zava Outdoors",
an outdoor retail company. The agent is a customer support chatbot that can:
- Answer questions about outdoor products (tents, backpacks, hiking clothing,
  footwear, camping gear, sleeping bags)
- Recommend products based on customer needs and activities
- Provide product specifications, care instructions, and safety guidance
- Compare products across brands

Use the agent framework pattern for a hosted agent on Microsoft Foundry.
Create: zava-outdoors/main.py, zava-outdoors/agent.yaml,
zava-outdoors/Dockerfile, zava-outdoors/requirements.txt
```

Verify the folder was created:

```bash
ls zava-outdoors/
# Expected: main.py  agent.yaml  Dockerfile  requirements.txt
```

### 2.2 Create the Product Catalog

```
Create zava-outdoors/data/products.json with this outdoor product catalog:

TENTS:
- id:1  TrailMaster X4 Tent, $250, OutdoorLiving — 4-person, polyester, water-resistant, freestanding
- id:8  Alpine Explorer Tent, $350, AlpineGear — 8-person, 3-season, detachable divider, waterproof
- id:15 SkyView 2-Person Tent, $200, OutdoorLiving — lightweight, color-coded poles, double-stitched

BACKPACKS:
- id:2  Adventurer Pro Backpack, $90, HikeMate — 40L, ergonomic, hydration compatible
- id:9  SummitClimber Backpack, $120, HikeMate — 60L, integrated rain cover, reflective

HIKING CLOTHING:
- id:3  Summit Breeze Jacket, $120, MountainStyle — windproof, water-resistant, packable
- id:10 TrailBlaze Hiking Pants, $75, MountainStyle — nylon, water-resistant, articulated knees

FOOTWEAR:
- id:4  TrekReady Hiking Boots, $140, TrekReady — leather, shock-absorbing, moisture-wicking

CAMPING GEAR:
- id:5  BaseCamp Folding Table, $60, CampBuddy — aluminum, adjustable legs, cup holders
- id:6  EcoFire Camping Stove, $80, EcoFire — stainless steel, fuel-efficient, eco-friendly

SLEEPING BAGS:
- id:7  CozyNights Sleeping Bag, $100, CozyNights — 3-season, synthetic insulation, 3.5 lbs

Each product should include: id, name, price, category, brand, description, features list,
care_instructions, and safety_notes fields.
For care_instructions include cleaning method, drying, and storage guidance.
For safety_notes include relevant warnings (e.g. no stove use inside tents, season limits for sleeping bags).
```

### 2.3 Configure the Agent System Prompt

```
Set the system instructions for the zava-outdoors agent:

You are the Zava Outdoors AI Shopping Assistant. You help customers find the perfect
outdoor gear for their adventures. You are knowledgeable, friendly, and safety-conscious.

CAPABILITIES:
- Product search and recommendations based on activity (hiking, camping, backpacking)
- Detailed product specifications and side-by-side comparisons (use table format)
- Care, maintenance, and safety guidance from product data
- Budget-conscious recommendations with exact prices

RULES:
- ONLY recommend products from the Zava Outdoors catalog loaded from data/products.json
- Always cite product name, price, and brand in recommendations
- For comparisons, always use a markdown table with key differentiators
- For safety questions, always include the product's safety_notes — err on caution
- If a product is not in the catalog, say so honestly and suggest the customer check zavaoutdoors.com
- Parse multi-part questions into individual lookups before answering

BRANDS: OutdoorLiving, HikeMate, MountainStyle, TrekReady, CampBuddy, EcoFire, CozyNights, AlpineGear
```

### 2.4 Wire the Product Data into the Agent

> ⚠️ **Critical step** — the agent scaffold won't automatically use the catalog. You must explicitly connect it.

```
Update zava-outdoors/main.py so that on startup it loads the product catalog from
data/products.json and the agent answers ONLY from that catalog data. The agent
should search the loaded products by name, category, brand, and price range.
Do not hallucinate products that are not in the catalog file.
```

### 2.5 Test Locally

```bash
cd zava-outdoors
```

```
Run the Zava Outdoors agent locally and test it with this query:
"I'm planning a 3-day hiking trip for two people. What tent, backpack, and sleeping
bag would you recommend within a $500 budget?"
```

Validate the response:
- Recommends specific products from the catalog (not invented ones)
- Prices add up and stay within budget
- Features are relevant to hiking

```
Test with one more query:
"Can I use the EcoFire stove inside my tent?"
```

Validate the agent returns a safety warning.

### ✅ Checkpoint

- [ ] `zava-outdoors/` folder contains `main.py`, `agent.yaml`, `Dockerfile`, `requirements.txt`
- [ ] `zava-outdoors/data/products.json` has 11 products with `care_instructions` and `safety_notes`
- [ ] Agent code loads and searches the product catalog
- [ ] Local test returns correct catalog-based answers

---

## Module 3 — Deploy Agent

**Goal:** Deploy the agent as a hosted agent on Foundry.

### 3.1 Verify Environment Variables

Your `.env` should already be loaded from Module 0. Confirm:

```bash
cd /workspaces/microsoft-foundry-skills-labs/zava-outdoors
echo $AZURE_AI_PROJECT_ENDPOINT        # should show your endpoint
echo $AZURE_AI_MODEL_DEPLOYMENT_NAME   # should show gpt-4.1
echo $AZURE_CONTAINER_REGISTRY_NAME    # should show your ACR name
```

> If these are empty, re-run: `cd /workspaces/microsoft-foundry-skills-labs && set -a && source .env && set +a`

### 3.2 Deploy

```
Deploy the agent in the zava-outdoors/ folder to Foundry,
using agent name "zava-outdoors-agent"
```

The `microsoft-foundry` skill orchestrates:

```
Building and deploying zava-outdoors-agent:<timestamp>...
Step 1: Building image in ACR...
Step 2: Image built at: <acr>.azurecr.io/zava-outdoors-agent:<timestamp>
Step 3: Creating agent version 1...
Agent deployment complete!
```

### 3.3 Verify the Deployed Agent

```
Invoke the zava-outdoors-agent with the query:
"What's the warmest sleeping bag you carry?"
```

Confirm it responds with the CozyNights Sleeping Bag ($100, 3-season, synthetic).

### 💡 Troubleshooting Deployment

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| ACR push fails | Wrong role on managed identity | Assign `Container Registry Repository Reader` (not just `AcrPull`) at the ACR repo scope |
| Agent status `Failed` | Incorrect project endpoint | Verify `AZURE_AI_PROJECT_ENDPOINT`; check it points to an active Foundry project |
| Container stuck in `Starting` | Missing env vars in agent.yaml | Check that `AZURE_AI_MODEL_DEPLOYMENT_NAME` is set in the deployment config |
| Docker auth error | ACR not logged in | Run `az acr login --name <acr-name>` |

### ✅ Checkpoint

- [ ] Docker image built and pushed to ACR
- [ ] Agent deployed and running on Microsoft Foundry
- [ ] Agent responds to queries via the hosted endpoint

---

## Module 4 — Evaluate & Observe

**Goal:** Run a baseline evaluation and identify areas for improvement.

### 4.1 Create an Evaluation Dataset

```
Create an evaluation dataset at zava-outdoors/.foundry/datasets/eval_baseline.jsonl
for the zava-outdoors-agent with these test cases in JSONL format.
Each line should have "query" and "expected_behavior" fields:

1. query: "Tell me about the TrailMaster X4 Tent"
   expected_behavior: "Mentions price ($250), brand (OutdoorLiving), 4-person, water-resistant"

2. query: "I need a backpack for a week-long backpacking trip"
   expected_behavior: "Recommends SummitClimber 60L over Adventurer Pro 40L for capacity"

3. query: "Compare the TrailMaster X4 and Alpine Explorer tents"
   expected_behavior: "Table format comparing price, capacity, brand, key features"

4. query: "What camping gear can I get for under $100?"
   expected_behavior: "Lists BaseCamp Folding Table ($60), EcoFire Stove ($80)"

5. query: "Do you sell kayaks?"
   expected_behavior: "Says kayaks are not in the catalog, suggests checking zavaoutdoors.com"

6. query: "Can I use the EcoFire stove inside my tent?"
   expected_behavior: "Safety warning against indoor use from product safety_notes"

7. query: "I'm going winter camping — what sleeping bag do you recommend?"
   expected_behavior: "Notes CozyNights is 3-season only, advises caution for winter use"

8. query: "How do I clean my CozyNights sleeping bag?"
   expected_behavior: "Care instructions: spot clean or gentle machine wash, hang dry, store dry"
```

### 4.2 Run the Baseline Evaluation

```
Run a batch evaluation against zava-outdoors-agent using
zava-outdoors/.foundry/datasets/eval_baseline.jsonl
Use evaluators: relevance, task_adherence, intent_resolution, indirect_attack
```

Results are saved under `.foundry/results/`.

### 4.3 Analyze Results

```
Give me an overview of the evaluation results for zava-outdoors-agent.
Highlight areas that need the most improvement.
```

Note your baseline scores — you'll compare after optimization.

### 4.4 Trace Analysis (if time permits)

```
Give me an overview of agent run summary for zava-outdoors-agent
in recent traces, and highlight issues worth attention.
```

> **Note:** Trace analysis requires App Insights connected to your Foundry project.

### ✅ Checkpoint

- [ ] Evaluation dataset created (8 test cases, `query` + `expected_behavior` fields)
- [ ] Baseline evaluation completed with scores recorded
- [ ] Identified 2–3 areas for improvement

---

## Module 5 — Optimize & Iterate

**Goal:** Improve the agent using prompt optimization, then redeploy and compare.

### 5.1 Optimize the Agent Prompt

```
Optimize the system prompt for zava-outdoors-agent based on the evaluation results.
Focus on improving:
1. Task adherence — ensure every recommendation cites exact catalog data (name, price, brand)
2. Relevance — better handle out-of-scope and edge-case queries
3. Intent resolution — parse multi-part customer questions into individual lookups
```

The optimizer:
- Analyzes evaluation failures
- Generates improved instructions
- Logs changes to `.foundry/OPTIMIZATION_LOG.md`

### 5.2 Review the Optimized Instructions

```
Show me the optimized instructions and explain what changed.
```

Common optimization areas:
- **Intent clarification** — decompose multi-part questions before answering
- **Catalog citation** — always include name + price + brand in every product mention
- **Out-of-scope** — standard response template for products not in catalog
- **Comparison format** — consistent table layout with key differentiators
- **Safety escalation** — explicit warnings drawn from `safety_notes` field

### 5.3 Redeploy the Optimized Agent

```
Deploy the optimized version of the zava-outdoors agent to Foundry
```

This creates **version 2** of the hosted agent.

### 5.4 Re-Evaluate and Compare

```
Run the same batch evaluation against the optimized zava-outdoors-agent
and compare results with the baseline.
```

| Evaluator | Baseline | Optimized | Goal |
|-----------|----------|-----------|------|
| Relevance | ? | ? | ⬆ improvement |
| Task Adherence | ? | ? | ⬆ improvement |
| Intent Resolution | ? | ? | ⬆ improvement |
| Safety (indirect attack) | ? | ? | maintain ≥95% |

### 5.5 Decide: Promote or Iterate

```
Show me the comparison between baseline and optimized evaluation results.
Should we promote the optimized version?
```

- **Quality gates passed** → promote v2
- **Still gaps** → run another optimization cycle

### ✅ Checkpoint

- [ ] Prompt optimization completed and reviewed
- [ ] Optimized agent redeployed as v2
- [ ] Re-evaluation shows measurable improvement
- [ ] Decision made to promote or iterate

---

## Appendix A — Zava Outdoors Product Catalog

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

> **Data adapted from** [Contoso Outdoors](https://github.com/Azure-Samples/contoso-web/tree/main/public), rebranded for the Zava Outdoors workshop scenario.

---

## Appendix B — The Observe Loop

This workshop follows the **Copilot-driven observability loop** from the
[Foundry Observability Skills](https://github.com/microsoft/foundry-observability-skills) reference:

```
    ┌─────────┐    ┌─────────┐    ┌──────────┐
    │  BUILD  │───▶│ DEPLOY  │───▶│ EVALUATE │
    └─────────┘    └─────────┘    └────┬─────┘
         ▲                             │
         │         ┌──────────┐        │
         └─────────│ OPTIMIZE │◀───────┘
                   └──────────┘

    Module:  M2         M3          M4          M5
```

---

## Appendix C — Workspace Structure After Completion

```
microsoft-foundry-skills-labs/
├── scripts/
│   ├── sample.env                        # Environment variable template
│   ├── setup-env.sh                      # Auto-discover Azure resources → .env
│   └── create-acr.sh                     # Create ACR + assign RBAC roles
├── zava-outdoors/                        # ← all agent code lives here
│   ├── main.py                           # Agent entry point
│   ├── agent.yaml                        # Deployment contract
│   ├── Dockerfile                        # Container image
│   ├── requirements.txt                  # Python deps
│   ├── data/
│   │   └── products.json                 # Product catalog (11 products)
│   └── .foundry/
│       ├── agent-metadata.yaml           # Agent metadata
│       ├── OPTIMIZATION_LOG.md           # Prompt change history
│       ├── datasets/
│       │   └── eval_baseline.jsonl       # Evaluation test cases
│       ├── results/                      # Evaluation results (per run)
│       └── evaluators/
│           └── optimized_instructions.md # Optimized system prompt
├── docs/
│   ├── PLAN.md                           # Workshop plan (high-level)
│   └── README.md                         # This file — step-by-step instructions
└── .env                                  # Local env vars (git-ignored)
```

---

## Appendix D — Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| `microsoft-foundry` skill not visible | Context overflow or not installed | `Ctrl+Shift+P` → *@azure: Install Azure Skills Globally*; start fresh chat |
| `Plugin not found` | Marketplace not registered | `/plugin marketplace add microsoft/azure-skills` then `/plugin install azure@azure-skills` |
| `Authentication failed` | Azure CLI session expired | `az login --use-device-code` then `az account show` |
| ACR push fails | Wrong role on managed identity | Assign `Container Registry Repository Reader` at ACR repo scope |
| Agent status `Failed` | Bad project endpoint or missing model | Verify `AZURE_AI_PROJECT_ENDPOINT` and `AZURE_AI_MODEL_DEPLOYMENT_NAME` |
| Container stuck `Starting` | Missing env vars in agent.yaml | Ensure model deployment name and project endpoint are in the config |
| Eval returns no results | Wrong dataset format | Must be JSONL with `query` and `expected_behavior` fields |
| Agent hallucinates products | Product data not loaded | Verify `main.py` loads `data/products.json` on startup |
| No traces available | App Insights not connected | Connect App Insights to your Foundry project in Azure portal |
| Eval judge errors | No judge model deployed | Deploy a chat-capable model (e.g., `gpt-4.1`) for evaluation |

---

## Appendix E — Resources

| Resource | Link |
|----------|------|
| Azure Skills Overview | https://learn.microsoft.com/en-us/azure/developer/azure-skills/overview |
| Azure Skills Install & Configure | https://learn.microsoft.com/en-us/azure/developer/azure-skills/install |
| Azure Skills Quickstart | https://learn.microsoft.com/en-us/azure/developer/azure-skills/quickstart |
| Microsoft Foundry Skill Reference | https://learn.microsoft.com/en-us/azure/developer/azure-skills/skills/microsoft-foundry |
| Foundry Observability Skills Lab | https://github.com/microsoft/foundry-observability-skills |
| Contoso Web (Data Source) | https://github.com/Azure-Samples/contoso-web/tree/main/public |

---

> 🎉 **Congratulations!** You built, deployed, evaluated, and optimized the **Zava Outdoors**
> AI Shopping Assistant using Azure Skills and the `microsoft-foundry` skill — entirely
> from natural language in your IDE.
