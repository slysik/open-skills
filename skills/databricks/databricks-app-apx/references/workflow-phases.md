# APX — Phases 1-6 (init, backend, frontend, testing, deploy, docs)

> Detail moved out of the router. Router: ../SKILL.md (or SKILL.md)

## Phase 1: Initialize

```bash
# Start APX development server
mcp-cli call apx/start '{}'
mcp-cli call apx/status '{}'
```

Create TodoWrite with tasks:
- Start servers ✓
- Design models
- Create API routes
- Add UI components
- Create pages
- Test & document

## Phase 2: Backend Development

### Create Pydantic Models

In `src/{app_name}/backend/models.py`:

**Follow 3-model pattern**:
- `EntityIn` - Input validation
- `EntityOut` - Complete output with computed fields
- `EntityListOut` - Performance-optimized summary

**See [backend-patterns.md](backend-patterns.md) for complete code templates.**

### Create API Routes

In `src/{app_name}/backend/router.py`:

**Critical requirements**:
- Always include `response_model` (enables OpenAPI generation)
- Always include `operation_id` (becomes frontend hook name)
- Use naming pattern: `listX`, `getX`, `createX`, `updateX`, `deleteX`
- Initialize 3-4 mock data samples for testing

**See [backend-patterns.md](backend-patterns.md) for complete CRUD templates.**

### Type Check

```bash
mcp-cli call apx/dev_check '{}'
```

Fix any Python type errors reported by basedpyright.

## Phase 3: Frontend Development

**Wait 5-10 seconds** after backend changes for OpenAPI client regeneration.

### Add UI Components

```bash
# Get shadcn add command
mcp-cli call shadcn/get_add_command_for_items '{
  "items": ["@shadcn/button", "@shadcn/card", "@shadcn/table",
            "@shadcn/badge", "@shadcn/select", "@shadcn/skeleton"]
}'
```

Run the command from project root with `--yes` flag.

### Create Pages

**List page**: `src/{app_name}/ui/routes/_sidebar/{entity}.tsx`
- Table view with all entities
- Suspense boundaries with skeleton fallback
- Formatted data (currency, dates, status colors)

**Detail page**: `src/{app_name}/ui/routes/_sidebar/{entity}.$id.tsx`
- Complete entity view with cards
- Update/delete mutations
- Back navigation

**See [frontend-patterns.md](frontend-patterns.md) for complete page templates.**

### Update Navigation

In `src/{app_name}/ui/routes/_sidebar/route.tsx`, add new item to `navItems` array.

## Phase 4: Testing

```bash
# Type check both backend and frontend
mcp-cli call apx/dev_check '{}'

# Test API endpoints
curl http://localhost:8000/api/{entities} | jq .
curl http://localhost:8000/api/{entities}/{id} | jq .

# Get frontend URL
mcp-cli call apx/get_frontend_url '{}'
```

Manually verify in browser:
- List page displays data
- Detail page shows complete info
- Mutations work (update, delete)
- Loading states work (skeletons)
- Browser console errors are automatically captured in APX dev logs

## Phase 5: Deployment & Monitoring

### Deploy to Databricks

Use DABs to deploy your APX application to Databricks. See the `databricks-asset-bundles` skill for complete deployment guidance.

### Monitor Application Logs

**Automated log checking with APX MCP:**

The APX MCP server can automatically check deployed application logs. Simply ask:
"Please check the deployed app logs for <app-name>"


The APX MCP will retrieve logs and identify issues automatically, including:
- Deployment status and errors
- Runtime exceptions and stack traces
- Both `[SYSTEM]` (deployment) and `[APP]` (application) logs
- Browser console errors (now included in APX dev logs)

**Manual log checking (reference):**

For direct CLI access:
```bash
databricks apps logs <app-name> --profile <profile-name>
```

**Key patterns to look for:**
- ✅ `Deployment successful` - App deployed correctly
- ✅ `App started successfully` - Application is running
- ❌ `Error:` - Check stack traces for issues

## Phase 6: Documentation

Create two markdown files:

**README.md**:
- Features overview
- Technology stack
- How app was created (AI tools + MCP servers used)
- Application architecture
- Getting started instructions
- API documentation
- Development workflow

**CODE_STRUCTURE.md**:
- Directory structure explanation
- Backend structure (models, routes, patterns)
- Frontend structure (routes, components, hooks)
- Auto-generated files warnings
- Guide for adding new features
- Best practices
- Common patterns
- Troubleshooting guide

