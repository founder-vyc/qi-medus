# Business Features Removal Plan

## Objective
Remove all business features except invoices and assistant, without breaking functionality.

## Source
Base on temp branch commit: cd033d6c0cee46640cb7404eab2f1611201371bc

## Packages to KEEP
- `packages/invoice` - Core invoice functionality
- `packages/db` - Database layer
- `packages/cache` - Caching 
- `packages/email` - Email service
- `packages/logger` - Logging
- `packages/ui` - UI components
- `packages/utils` - Utilities
- `packages/supabase` - Backend
- `packages/tsconfig` - TypeScript config
- `packages/notifications` - Notifications
- `packages/encryption` - Security
- `packages/events` - Event system
- `packages/engine-client` - Engine client

## Packages to REMOVE
- `packages/accounting` - Accounting features
- `packages/app-store` - App marketplace
- `packages/categories` - Category management
- `packages/customers` - Customer management
- `packages/desktop-client` - Desktop app client
- `packages/documents` - Document management
- `packages/import` - Import functionality
- `packages/inbox` - Inbox features
- `packages/job-client` - Job client
- `packages/jobs` - Background jobs
- `packages/location` - Location services
- `packages/plans` - Subscription plans
- `packages/workbench` - Workbench features

## Dashboard Routes to KEEP
- `apps/dashboard/src/app/[locale]/(app)/(sidebar)/[[...chatId]]` - Assistant/Chat
- `apps/dashboard/src/app/[locale]/(app)/(sidebar)/invoices` - Invoices
- `apps/dashboard/src/app/[locale]/(app)/(sidebar)/account` - Account settings
- `apps/dashboard/src/app/[locale]/(app)/(sidebar)/settings` - Settings

## Dashboard Routes to REMOVE
- `apps/dashboard/src/app/[locale]/(app)/(sidebar)/customers` - Customer management
- `apps/dashboard/src/app/[locale]/(app)/(sidebar)/inbox` - Inbox
- `apps/dashboard/src/app/[locale]/(app)/(sidebar)/tracker` - Time tracker
- `apps/dashboard/src/app/[locale]/(app)/(sidebar)/transactions` - Transactions
- `apps/dashboard/src/app/[locale]/(app)/(sidebar)/vault` - Vault/documents
- `apps/dashboard/src/app/[locale]/(app)/(sidebar)/apps` - App store
- `apps/dashboard/src/app/[locale]/(app)/(sidebar)/upgrade` - Upgrade/plans

## Apps to Evaluate/Remove
- `apps/desktop` - Desktop app (likely remove)
- `apps/docs` - Documentation (keep for reference)
- `apps/website` - Marketing site (evaluate)
- `apps/worker` - Background worker (evaluate if needed)

## Configuration Updates Needed

### 1. Root `package.json`
Remove from workspaces array

### 2. `turbo.json`
Remove pipeline entries for deleted packages

### 3. Dashboard `package.json`
Remove dependencies on deleted packages

### 4. API routes
Remove API endpoints for deleted features

## Execution Steps
1. Copy full temp branch content to working directory
2. Delete package directories
3. Delete route directories  
4. Update package.json workspaces
5. Update turbo.json
6. Update dependencies
7. Run build test
8. Fix any broken imports
9. Run linter
10. Commit changes

